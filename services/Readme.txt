-If you want to keep it incredibly simple on Linux without messing around with Python or actual Excel binaries, we can use simple **CSV files** (Comma-Separated Values).

Browsers and spreadsheet apps (like Excel or LibreOffice) read them perfectly, and we can write the data directly inside our terminal using a standard Linux text editor or raw echo commands.

Here is how to set up the data, the ConfigMap, and the service completely natively in Linux.

---

## 1. Create the Mock Data Files in Linux

Run these commands in your Linux terminal to create two quick spreadsheets with basic data:

```bash
# Create the first file (Sales Data)
cat << 'EOF' > sales_data.csv
Product,Units Sold,Revenue
Laptops,50,45000
Monitors,120,24000
Keyboards,300,15000
EOF

# Create the second file (User Data)
cat << 'EOF' > user_data.csv
UserID,Name,Role
101,Alice Smith,Admin
102,Bob Jones,Editor
103,Charlie Brown,Viewer
EOF

```

---

## 2. Create the ConfigMap & Deployment

Now, feed those two Linux-generated files into your Kubernetes cluster.

```bash
kubectl create configmap csv-config \
  --from-file=sales_data.csv \
  --from-file=user_data.csv

```

Save the deployment configuration below as `csv-service.yaml`. It sets up the Nginx server to hold your files and builds the `ClusterIP` service:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: csv-server
  labels:
    app: csv-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: csv-app
  template:
    metadata:
      labels:
        app: csv-app
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: csv-volume
          mountPath: /usr/share/nginx/html/sales_data.csv
          subPath: sales_data.csv
        - name: csv-volume
          mountPath: /usr/share/nginx/html/user_data.csv
          subPath: user_data.csv
      volumes:
      - name: csv-volume
        configMap:
          name: csv-config
---
apiVersion: v1
kind: Service
metadata:
  name: csv-clusterip-service
spec:
  type: ClusterIP
  selector:
    app: csv-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80

```

Apply it to your cluster:

```bash
kubectl apply -f csv-service.yaml

```

---

## 3. Launch and View in the Browser

To tunnel into the `ClusterIP` service from your local Linux environment, start up the port-forward tool:

```bash
kubectl port-forward svc/csv-clusterip-service 8080:80

```

Keep that terminal running. Now open your local web browser and head to:

* `http://localhost:8080/sales_data.csv`
* `http://localhost:8080/user_data.csv`

Your browser will instantly let you open or save the files, which you can open directly in Excel or any system viewer!

If you want to keep it incredibly simple on Linux without messing around with Python or actual Excel binaries, we can use simple **CSV files** (Comma-Separated Values).

Browsers and spreadsheet apps (like Excel or LibreOffice) read them perfectly, and we can write the data directly inside our terminal using a standard Linux text editor or raw echo commands.

Here is how to set up the data, the ConfigMap, and the service completely natively in Linux.

---

## 1. Create the Mock Data Files in Linux

Run these commands in your Linux terminal to create two quick spreadsheets with basic data:

```bash
# Create the first file (Sales Data)
cat << 'EOF' > sales_data.csv
Product,Units Sold,Revenue
Laptops,50,45000
Monitors,120,24000
Keyboards,300,15000
EOF

# Create the second file (User Data)
cat << 'EOF' > user_data.csv
UserID,Name,Role
101,Alice Smith,Admin
102,Bob Jones,Editor
103,Charlie Brown,Viewer
EOF

```

---

## 2. Create the ConfigMap & Deployment

Now, feed those two Linux-generated files into your Kubernetes cluster.

```bash
kubectl create configmap csv-config \
  --from-file=sales_data.csv \
  --from-file=user_data.csv

```

Save the deployment configuration below as `csv-service.yaml`. It sets up the Nginx server to hold your files and builds the `ClusterIP` service:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: csv-server
  labels:
    app: csv-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: csv-app
  template:
    metadata:
      labels:
        app: csv-app
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: csv-volume
          mountPath: /usr/share/nginx/html/sales_data.csv
          subPath: sales_data.csv
        - name: csv-volume
          mountPath: /usr/share/nginx/html/user_data.csv
          subPath: user_data.csv
      volumes:
      - name: csv-volume
        configMap:
          name: csv-config
---
apiVersion: v1
kind: Service
metadata:
  name: csv-clusterip-service
spec:
  type: ClusterIP
  selector:
    app: csv-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80

```

Apply it to your cluster:

```bash
kubectl apply -f csv-service.yaml

```

---

## 3. Launch and View in the Browser

To tunnel into the `ClusterIP` service from your local Linux environment, start up the port-forward tool:

```bash
kubectl port-forward svc/csv-clusterip-service 8080:80

```

Keep that terminal running. Now open your local web browser and head to:

* `http://localhost:8080/sales_data.csv`
* `http://localhost:8080/user_data.csv`

Your browser will instantly let you open or save the files, which you can open directly in Excel or any system viewer!

` with the actual network IP of your masterThat terminal output looks perfect! The tunnel is open, and Kubernetes is listening for connections.

Since your terminal output shows it's running on a remote server (`system@k8s-master`), your browser on your physical laptop/PC cannot reach `localhost:8080` directly. `localhost` inside that terminal refers to the **k8s-master server**, not your own computer.

Here are the two ways to fix this so you can view the files in your local browser.

---

## Method 1: The Quickest Fix (Bind to All Interfaces)

By default, `kubectl port-forward` only listens to connections coming from *inside* that specific master machine. You can tell it to listen to external connections (like your personal computer) by adding the `--address 0.0.0.0` flag.

1. Go back to your `k8s-master` terminal and press `Ctrl + C` to stop the current forward.
2. Run this updated command instead:

```bash
kubectl port-forward svc/csv-clusterip-service --address 0.0.0.0 8080:80

```

3. Now, open the browser on your laptop or PC and use the **IP address of your k8s-master server** instead of localhost:

```text
http://<K8S-MASTER-IP>:8080/sales_data.csv

```

*(Replace `<K8S-MASTER-IP>` with the actual network IP of your master node, for example: `[http://192.168.1.50:8080/salesThat](http://192.168.1.50:8080/salesThat) terminal output looks perfect! The tunnel is open, and Kubernetes is listening for connections.

Since your terminal output shows it's running on a remote server (`system@k8s-master`), your browser on your physical laptop/PC cannot reach `localhost:8080` directly. `localhost` inside that terminal refers to the **k8s-master server**, not your own computer.

Here are the two ways to fix this so you can view the files in your local browser.

---

## Method 1: The Quickest Fix (Bind to All Interfaces)

By default, `kubectl port-forward` only listens to connections coming from *inside* that specific master machine. You can tell it to listen to external connections (like your personal computer) by adding the `--address 0.0.0.0` flag.

1. Go back to your `k8s-master` terminal and press `Ctrl + C` to stop the current forward.
2. Run this updated command instead:

```bash
kubectl port-forward svc/csv-clusterip-service --address 0.0.0.0 8080:80

```

3. Now, open the browser on your laptop or PC and use the **IP address of your k8s-master server** instead of localhost:

```text
http://<K8S-MASTER-IP>:8080/sales_data.csv

```

*(Replace `<K8S-MASTER-IP>` with the actual network IP of your master node, for example: `[http://192.168.1.50:8080/sales_data.csv](http://192.168.1.50:8080/sales_data.csv)`)*

---

## Method 2: The Secure Way (SSH Tunneling)

If your master node is behind a strict firewall or cloud security group that blocks port `8080`, you can safely bridge the connection through SSH right from your personal computer's terminal.

1. Leave your current `kubectl port-forward` command running exactly as it is on the `k8s-master` server.
2. Open a **brand new terminal window on your personal computer (laptop/desktop)**.
3. Run this SSH command to map your local port `8080` directly to the master's port `8080`:

```bash
ssh -L 8080:localhost:8080 system@<K8S-MASTER-IP>

```

*(Replace `<K8S-MASTER-IP>` with the actual IP address or hostname you use to connect to your master node).*

4. Once you log in, keep that new terminal open. You can now open your local browser and go to your original address:

```text
http://localhost:8080/sales_data.csv
```</K8S-MASTER-IP></K8S-MASTER-IP></K8S-MASTER-IP></K8S-MASTER-IP>

```

You are 100% correct! Your pod is running on the worker node (`k8s-worker-1`), which has an internal IP of `192.168.31.158`.

When you run `kubectl port-forward`, Kubernetes automatically handles forwarding the traffic from your master node, across the cluster network, and straight into the pod on that worker node. You don't have to change your commands to target the worker directly—Kubernetes does the heavy lifting for you.

Since your master node IP is **`192.168.31.157`**, let's use that to get this opened in your browser right now.

---

## The Solution

On your master node terminal (`system@k8s-master`), spin up the port forwarder telling it to listen to outside connections using `--address 0.0.0.0`:

```bash
kubectl port-forward svc/csv-clusterip-service --address 0.0.0.0 8080:80

```

Once it says it's forwarding, switch over to the web browser on your personal computer/laptop, and go straight to these URLs:

* **`[http://192.168.31.157:8080/sales_data.csv](http://192.168.31.157:8080/sales_data.csv)`**
* **`[http://192.168.31.157:8080/user_data.csv](http://192.168.31.157:8080/user_data.csv)`**

### ⚠️ A Quick Troubshooting Note

If the browser window spins endlessly or says "Connection Timed Out", it means the firewall on your `k8s-master` node is blocking port `8080`.

If that happens, you can easily open it up on your master node by running:

```bash
sudo ufw allow 8080/tcp

```

*(Or if you are using a cloud provider like AWS/OpenStack, make sure port 8080 is opened in your Security Group/Inbound rules for `192.168.31.157`).*You are 100% correct! Your pod is running on the worker node (`k8s-worker-1`), which has an internal IP of `192.168.31.158`.

When you run `kubectl port-forward`, Kubernetes automatically handles forwarding the traffic from your master node, across the cluster network, and straight into the pod on that worker node. You don't have to change your commands to target the worker directly—Kubernetes does the heavy lifting for you.

Since your master node IP is **`192.168.31.157`**, let's use that to get this opened in your browser right now.

---

## The Solution

On your master node terminal (`system@k8s-master`), spin up the port forwarder telling it to listen to outside connections using `--address 0.0.0.0`:

```bash
kubectl port-forward svc/csv-clusterip-service --address 0.0.0.0 8080:80

```

Once it says it's forwarding, switch over to the web browser on your personal computer/laptop, and go straight to these URLs:

* **`[http://192.168.31.157:8080/sales_data.csv](http://192.168.31.157:8080/sales_data.csv)`**
* **`[http://192.168.31.157:8080/user_data.csv](http://192.168.31.157:8080/user_data.csv)`**

### ⚠️ A Quick Troubshooting Note

If the browser window spins endlessly or says "Connection Timed Out", it means the firewall on your `k8s-master` node is blocking port `8080`.

If that happens, you can easily open it up on your master node by running:

```bash
sudo ufw allow 8080/tcp

```

*(Or if you are using a cloud provider like AWS/OpenStack, make sure port 8080 is opened in your Security Group/Inbound rules for `192.168.31.157`).*


