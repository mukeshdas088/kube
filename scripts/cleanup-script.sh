#!/bin/bash
# cleanup-k8s.sh
# Deletes common Kubernetes resources in the current namespace,
# and ignores errors if the resources do not exist.

set -e

echo "Deleting all workload and service objects in the current namespace..."

kubectl delete deployment,statefulset,daemonset,replicaset,replicationcontroller \
  --all --ignore-not-found=true

kubectl delete pod,service,configmap,secret,pvc,job,cronjob,ingress,networkpolicy \
  --all --ignore-not-found=true

echo "Deleting all custom resources (if any)..."
kubectl api-resources --verbs=delete --namespaced -o name | \
  xargs -r -n 1 kubectl delete --all --ignore-not-found=true

echo "Cleanup complete."
