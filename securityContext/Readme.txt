system@k8s-master:~/kube/securityContext$ kubectl logs security-context-demo -c writer
total 4
-rw-r--r--    1 3000     2000            16 May 22 15:33 message.txt
system@k8s-master:~/kube/securityContext$ kubectl logs security-context-demo -c reader
Reading data as user 5000:
Writing data...
total 4
-rw-r--r--    1 3000     2000            16 May 22 15:33 message.txt
system@k8s-master:~/kube/securityContext$ kubectl exec -it security-context-demo -c writer -- id
uid=3000 gid=4000 groups=2000,4000
system@k8s-master:~/kube/securityContext$ kubectl exec -it security-context-demo -c reader -- id
uid=5000 gid=4000 groups=2000,4000
system@k8s-master:~/kube/securityContext$ kubectl exec -it security-context-demo -c writer -- cat /proc/self/attr/current
cri-containerd.apparmor.d (enforce)



============================================================================================================================


Here is how you can step-by-step deploy, test, and verify the multi-container manifest to see exactly how these permissions handle files under the hood.

### 1. Apply the Manifest

Save the fixed YAML to a file named security-demo.yaml on your master node and create the pod:

```bash
kubectl apply -f security-demo.yaml

```

Give it a few seconds to pull the alpine image and spin up both containers. Verify it is running cleanly:

```bash
kubectl get pod security-context-demo

```

---

### 2. Verify the Writer Container (UID 3000)

Let's check the logs of the writer container first to see its own filesystem point of view. It created /data/message.txt.

```bash
kubectl logs security-context-demo -c writer

```

**Expected output layout:**

```text
Writing data...
total 4
-rw-r--r--    1 3000     2000            16 May 22 21:05 message.txt

```

> **What this proves:** Notice the group owner of message.txt is **2000** (fsGroup), even though the primary group of the container process was set via runAsGroup to 4000. The fsGroup successfully forced the volume block layer to assign GID 2000.

---

### 3. Verify the Reader Container (UID 5000)

Now let's check the logs of the reader container. This container ran with runAsUser: 5000, making it a completely separate unprivileged user identity from the writer.

```bash
kubectl logs security-context-demo -c reader

```

**Expected output layout:**

```text
Reading data as user 5000:
Writing data...
total 4
-rw-r--r--    1 3000     2000            16 May 22 21:05 message.txt

```

> **What this proves:** User 5000 read the file perfectly without a Permission denied error. Since the directory is controlled by fsGroup: 2000, the file is shared transparently across differing unprivileged UIDs.

---

### 4. Check the Process Identity and SELinux Labels

To verify the seLinuxOptions and process runtime state, execute an interactive command directly inside one of the running containers:

```bash
kubectl exec -it security-context-demo -c writer -- id

```

**Expected output layout:**

```text
uid=3000 gid=4000 groups=2000,4000

```

* uid=3000: Set correctly by runAsUser.
* gid=4000: Set correctly by runAsGroup.
* groups=2000: Kubernetes automatically appended your fsGroup to the user's supplementary group list so it has execution rights on the volume.

If your host operating system (like Red Hat, Fedora, or Rocky Linux) has SELinux active, you can check that the process layer matches your level specification by viewing the containerized process identity:

```bash
kubectl exec -it security-context-demo -c writer -- cat /proc/self/attr/current

```

**Expected output layout:**

```text
system_u:system_r:container_t:s0:c123,c456

```

The Multi-Category Security (MCS) level fields c123,c456 map directly back to your manifest configuration, keeping this pod tightly isolated at the Linux kernel level.

========================================================================
