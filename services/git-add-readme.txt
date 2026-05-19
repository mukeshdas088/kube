Awesome! Glad to hear the push went through successfully.

Here is a clean, organized summary of the entire workflow you just built—from creating the spreadsheet files to deploying them on Kubernetes and syncing your code with GitHub. You can save this straight into your notes for next time.

---

## 🛠️ Phase 1: Local Data & Kubernetes Configuration

### Step 1: Create the Source Files Natively in Linux

You created two clean, lightweight data sheets using standard CSV formats:

```bash
# Create Sales Data Spreadsheet
cat << 'EOF' > sales_data.csv
Product,Units Sold,Revenue
Laptops,50,45000
Monitors,120,24000
Keyboards,300,15000
EOF

# Create User Data Spreadsheet
cat << 'EOF' > user_data.csv
UserID,Name,Role
101,Alice Smith,Admin
102,Bob Jones,Editor
103,Charlie Brown,Viewer
EOF

```

### Step 2: Inject Files into a ConfigMap

You bundled both local files into a single Kubernetes configuration resource:

```bash
kubectl create configmap csv-config \
  --from-file=sales_data.csv \
  --from-file=user_data.csv

```

### Step 3: Deploy the Pods & ClusterIP Service

You wrote and applied a unified manifest (`csv-service.yaml`) containing:

1. **A Deployment:** Spawning an Nginx pod on the worker node (`k8s-worker-1`), mounting your specific files from the ConfigMap directly into Nginx's HTML folder (`/usr/share/nginx/html/`).
2. **A ClusterIP Service:** Setting up stable, internal networking on port `80`.

```bash
kubectl apply -f csv-service.yaml

```

### Step 4: Expose to Your Local Browser

Because a ClusterIP service is hidden inside the cluster network, you bound the forwarder to all network interfaces on the master node (`0.0.0.0`), allowing external client machines on your network to securely access it:

```bash
kubectl port-forward svc/csv-clusterip-service --address 0.0.0.0 8080:80

```

* **Browser Access:** `[http://192.168.31.157:8080/sales_data.csv](http://192.168.31.157:8080/sales_data.csv)`

---

## 💻 Phase 2: Fixing SSH Permissions & Git Push

When Git rejected your custom key file (`yes`) with a `Permission denied` error, you safely routed it into the official Linux SSH profile.

### Step 5: Relocate Custom Keys & Set Strict Linux Permissions

```bash
# 1. Ensure the hidden SSH configuration folder exists
mkdir -p ~/.ssh

# 2. Relocate and rename the custom keys to standard profiles
mv ~/kube/yes ~/.ssh/id_ed25519
mv ~/kube/yes.pub ~/.ssh/id_ed25519.pub

# 3. Apply strict, mandatory Linux file security permissions
chmod 700 ~/.ssh              # Owner-only access to folder
chmod 600 ~/.ssh/id_ed25519    # Private key must be completely secret
chmod 644 ~/.ssh/id_ed25519.pub # Public key is readable

```

### Step 6: Authenticate and Push to GitHub

```bash
# Test the handshake directly with GitHub
ssh -T git@github.com

# Safely push your working manifests to your repository
git push -u origin main

```










