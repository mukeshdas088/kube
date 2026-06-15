# Kubernetes Control-Plane Outage & CNI Restoration Report

## 1. What is the Tigera Operator, Why Did it Fail, and How We Fixed It?

### What it is:
The **Tigera Operator** is an infrastructure controller used to deploy, manage, and maintain the lifecycle of **Project Calico**, which acts as the Container Network Interface (CNI) for the cluster. It sits in the `tigera-operator` namespace and automatically provisions the internal network components like IP routing tables, network policies, and the `calico-node` DaemonSet.

### The Failure:
During a cluster cleanup script execution, a destructive global command (`kubectl delete ... --all-namespaces`) bypassed safety loops. This obliterated the `tigera-operator` namespace, its Custom Resource Definitions (CRDs), and its tracking finalizers. 

When we attempted to restore it via the standard operator path, the cluster encountered a scheduling deadlock:
* The control-plane node had strict worker selection constraints.
* The remaining worker node (`k8s-worker-1`) was completely offline (`NotReady,SchedulingDisabled`).
* Because the operator is configured by default to schedule on active worker nodes, the new operator pod sat indefinitely in a `Pending` state.

### How We Fixed It:
Instead of forcing a worker-dependent operator back into a broken single-node cluster, we **bypassed the Tigera Operator completely** and switched to the **Direct Calico Manifest Deployment**. 

We executed:
bash
# 1. Purged the broken operator framework
kubectl delete namespace tigera-operator --ignore-not-found

# 2. Deployed Calico directly into the system layer as a native DaemonSet
kubectl apply -f [https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml](https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml)



Deploying it directly as a native `DaemonSet` forced a healthy instance of `calico-node` to attach directly to the master node (`k8s-master`), overriding the worker node requirements and restoring the host network fabric.

---

## 2. How CoreDNS and Pod Creation Depend on the CNI

In Kubernetes, **Pod Creation** and internal **CoreDNS name resolution** are entirely dependent on a fully functional CNI provider. When the network plugin was deleted, it broke the communication loop shown below:


+-------------------------------------------------------------+
|                     Kubernetes API Server                   |
+-------------------------------------------------------------+
                               |
                               | Assigns IP & Configures veth
                               v
+------------------+   +------------------+   +---------------+
|   CoreDNS Pod    |   |  Container vnet  |   | User App Pod  |
| (Stuck in Error) |<--|   (Calico CNI)   |-->| (Container    |
+------------------+   +------------------+   |  Creating)    |
                                              +---------------+



### Pod Scheduling & `ContainerCreating` Lockup:

When you execute `kubectl run`, the API server schedules the pod, and the local machine's `kubelet` initiates the container runtime environment. However, before the pod can transition to a `Running` state, it pauses to wait for a network setup hook.

* `kubelet` calls the host network bridge to request a virtual ethernet (`veth`) pair and an IP address allocation from the **IPAM (IP Address Management)** pool.
* Because Calico was deleted, there was no network plugin to respond to this request.
* As a result, the pod stays frozen indefinitely in the `ContainerCreating` status.

### CoreDNS `CrashLoopBackOff` Loop:

CoreDNS handles all internal domain resolutions within the cluster. It requires a stable cluster IP interface to bind its internal DNS server listeners.
Without a working CNI, CoreDNS pods cannot acquire an IP endpoint. When the CoreDNS binary executes inside the container and finds no available network interface to bind to, it crashes instantly with a critical network error. Because Kubernetes tries to restart failed core system services automatically, the pod gets caught in a continuous loop of crashing and restarting (`CrashLoopBackOff`).

Once the direct `calico-node` went live on the host node, it instantly configured the network bridges, assigned cluster-internal IPs, and allowed both CoreDNS and user pods to transition smoothly into a `Running` state.

---

## 3. Why `kubectl run` Fails on Network Timeouts vs. Pre-Downloading via `crictl`

During an internet or configuration outage on a control plane, a common roadblock occurs where running an image fails via standard commands but can be forced to work using container-level pre-caching.

### The Problem with `kubectl run`:

When you issue a standard `kubectl run nginx --image=nginx`, the default configuration for Kubernetes deployments tells the container runtime (`containerd`) to connect to the external public container registry (like Docker Hub) to check if a newer digest of the tag exists.

* This check requires active, external internet access.
* If your cluster network layer or external DNS configuration (`/etc/resolv.conf`) is broken or timed out, the image pull worker will hang and ultimately fail with an `ImagePullBackOff` or `ErrImagePull` error.

### Why Pre-Downloading with `crictl` Works:

`crictl` is a low-level debug utility that communicates directly with your container runtime interface socket (`unix:///var/run/containerd/containerd.sock`), completely bypassing the Kubernetes control plane and API server scheduling logic.

By manually pulling the image directly into the machine's local hardware layer via:

bash
sudo crictl pull nginx:latest



the container image is injected straight into the local engine cache.

### Combining Pre-Caching with the Offline Workspace Override:

To utilize this pre-cached image cleanly without triggering an external internet call that will time out, we use a customized `k-run-offline` function that applies a localized override block to the pod submission layout:

bash
# Explicitly sets the Pull Policy to use the host machine's local cache
--overrides='{"spec":{"containers":[{"name":"app","image":"nginx","imagePullPolicy":"IfNotPresent"}]}}'



Setting `imagePullPolicy: IfNotPresent` instructs `kubelet` to inspect the local `crictl` image pool first. Because it finds the image already cached locally on the disk, it skips the network-dependent external check entirely, allowing the container to deploy in a completely offline environment.


