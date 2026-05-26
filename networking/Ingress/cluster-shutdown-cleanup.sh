#!/bin/bash

# Ensure script is running with bash for array handling
echo "================================================================="
echo "🛑 KUBERNETES ULTRA-CLEANUP & NODE SHUTDOWN PREPARATION SCRIPT"
echo "================================================================="

# --- 1. SET DEFAULT NAMESPACE TO DEFAULT ---
echo "🔄 Step 1: Resetting current context namespace to 'default'..."
kubectl config set-context --current --namespace=default

# --- 2. PROTECT SYSTEM NAMESPACES ---
# We must filter out core system namespaces so we don't brick the cluster plane!
PROTECTED_NAMESPACES="default|kube-system|kube-public|kube-node-lease|ingress-nginx"

# Get all custom namespaces
CUSTOM_NS=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep -vE "^(${PROTECTED_NAMESPACES})$")

# --- 3. INGRESS & INGRESS CONTROLLER CLEANUP ---
echo "🌐 Step 2: Cleaning up Ingress routing layers..."
# Delete all custom ingresses across all namespaces
kubectl delete ingress --all --all-namespaces --timeout=60s

# If you installed the ingress controller via manifest, delete its namespace safely
if kubectl get namespace ingress-nginx >/dev/null 2>&1; then
    echo "🧹 Removing Ingress Nginx Controller namespace..."
    kubectl delete namespace ingress-nginx --timeout=90s
fi

# --- 4. DELETE CUSTOM NAMESPACES (Tears down Deployments, Pods, Services) ---
echo "📦 Step 3: Deleting custom namespaces..."
if [ -z "$CUSTOM_NS" ]; then
    echo "ℹ️ No custom namespaces found to delete."
else
    for ns in $CUSTOM_NS; do
        echo "🗑️ Terminating namespace: $ns (This deletes all pods, deploys, & services inside it)..."
        kubectl delete namespace "$ns" --async
    done
fi

# --- 5. CLEAN UP EXTRA APPS IN DEFAULT NAMESPACE ---
echo "🧹 Step 4: Cleaning up non-system workloads left in 'default' namespace..."
kubectl delete deployment,statefulset,daemonset,replicaset,pods,services --all -n default --timeout=60s

# --- 6. STORAGE RETRIEVAL & DELETION (PVC then PV) ---
echo "💾 Step 5: Executing cascading storage cleanup..."
echo "Removing all PersistentVolumeClaims (PVCs)..."
kubectl delete pvc --all --all-namespaces --timeout=60s

echo "Removing all backing PersistentVolumes (PVs)..."
kubectl delete pv --all --timeout=60s

# --- 7. CLEAN UP ANYTHING MISSED (StorageClasses, CRDs, ClusterRoleBindings) ---
echo "🧹 Step 6: Purging global cluster configurations..."
# Clears out any lingering custom local storage classes
kubectl get storageclass -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep -v "standard" | xargs -I {} kubectl delete storageclass {}

# --- 8. CORDON WORKER NODES (Make Unschedulable) ---
echo "🏗️ Step 7: Cordoning worker nodes to prevent scheduling..."
WORKER_NODES=$(kubectl get nodes -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep -v "master\|controlplane")

if [ -z "$WORKER_NODES" ]; then
    echo "ℹ️ No dedicated worker nodes detected or already managed."
else
    for node in $WORKER_NODES; do
        echo "🔒 Cordoning node: $node (Setting to SchedulingDisabled)..."
        kubectl cordon "$node"
        
        echo "🏃 Evicting remaining non-daemon pods from $node..."
        kubectl drain "$node" --ignore-daemonsets --delete-emptydir-data --force --timeout=60s
    done
fi

echo "================================================================="
echo "✅ CLUSTER IS CLEANED, CORDONED, AND SAFELY PREPARED FOR SHUTDOWN."
echo "================================================================="
