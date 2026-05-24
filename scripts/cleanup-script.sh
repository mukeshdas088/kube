#!/bin/bash
# cleanup-k8s.sh
# Deletes resources inside a specific namespace, then deletes the namespace itself.

# Exit immediately if a command exits with a non-zero status, 
# but allow errors to be handled cleanly where specified.
set -e

# 1. Check if a namespace argument was passed
TARGET_NS=$1

if [ -z "$TARGET_NS" ]; then
    echo "Error: Please specify a namespace."
    echo "Usage: $0 <namespace-name>"
    exit 1
fi

# 2. Safety check to prevent accidental deletion of core system namespaces
if [[ "$TARGET_NS" =~ ^(kube-system|kube-public|kube-node-lease|default|calico-system|calico-apiserver|tigera-operator)$ ]]; then
    echo "Danger: Deleting system namespace '$TARGET_NS' is blocked for safety."
    exit 1
fi

echo "Deleting all workload and service objects in namespace: $TARGET_NS..."
kubectl delete deployment,statefulset,daemonset,replicaset,replicationcontroller \
  --all --namespace="$TARGET_NS" --ignore-not-found=true

kubectl delete pod,service,configmap,secret,pvc,job,cronjob,ingress,networkpolicy \
  --all --namespace="$TARGET_NS" --ignore-not-found=true

echo "Deleting all custom resources (if any) in namespace: $TARGET_NS..."
kubectl api-resources --verbs=delete --namespaced -o name | \
  xargs -r -n 1 kubectl delete --all --namespace="$TARGET_NS" --ignore-not-found=true

echo "Finally, deleting the namespace object '$TARGET_NS' itself..."
kubectl delete namespace "$TARGET_NS" --ignore-not-found=true

echo "Cleanup of '$TARGET_NS' complete."
