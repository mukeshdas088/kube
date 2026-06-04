kubectl create deployment dep-1 --image=nginx --replicas=2
kubectl get pods --show-labels
kubectl patch deployments.apps dep-1 -p '{"spec":{"template":{"metadata":{"labels":{"env":"prod"}}}}}'
kubectl get pods --show-labels
