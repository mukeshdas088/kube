kubectl create deployment dep-1 --image=nginx --replicas=2
kubectl scale deployment dep-1 --replicas=3
kubectl get pods -w
