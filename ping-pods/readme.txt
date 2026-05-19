kubectl label node k8s-worker-1 env=prod



kubectl apply -f configmap.yaml -f python-dep.yaml -f nginx-dep.yaml --namespace=default





system@k8s-master:~/ping-pods$ kubectl exec -it python-dep-764987cd74-gm4bn -- python /app/ping.py

--- Pinging 8.8.8.8 ---

PING 8.8.8.8 (8.8.8.8): 56 data bytes

64 bytes from 8.8.8.8: seq=0 ttl=111 time=76.513 ms



--- 8.8.8.8 ping statistics ---

1 packets transmitted, 1 packets received, 0% packet loss

round-trip min/avg/max = 76.513/76.513/76.513 ms				
