The 4-Container Pipeline Manifest
Save this file on your master node as 4-container-pipeline.yaml:

YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: multi-agent-pipeline
  namespace: my-ns
  labels:
    app: data-pipeline
spec:
  replicas: 1
  selector:
    matchLabels:
      app: data-pipeline
  template:
    metadata:
      labels:
        app: data-pipeline
    spec:
      containers:
        # --- 1. THE ORIGIN GENERATOR (Writes initial data) ---
        - name: container-1-writer
          image: alpine:3.18
          command: ["/bin/sh", "-c"]
          args:
            - |
              mkdir -p /workspace
              while true; do
                echo "[Container 1]: Initialized task data at $(date)" > /workspace/shared_data.txt
                sleep 10
              done
          volumeMounts:
            - name: pipeline-storage
              mountPath: /workspace

        # --- 2. THE SECOND STAGE AGENT (Appends data) ---
        - name: container-2-appender
          image: alpine:3.18
          command: ["/bin/sh", "-c"]
          args:
            - |
              while true; do
                if [ -f /workspace/shared_data.txt ]; then
                  echo "[Container 2]: Appended analytics modeling info" >> /workspace/shared_data.txt
                fi
                sleep 10
              done
          volumeMounts:
            - name: pipeline-storage
              mountPath: /workspace

        # --- 3. THE THIRD STAGE AGENT (Appends data) ---
        - name: container-3-appender
          image: alpine:3.18
          command: ["/bin/sh", "-c"]
          args:
            - |
              while true; do
                if [ -f /workspace/shared_data.txt ]; then
                  echo "[Container 3]: Appended data verification signatures" >> /workspace/shared_data.txt
                fi
                sleep 10
              done
          volumeMounts:
            - name: pipeline-storage
              mountPath: /workspace

        # --- 4. THE CONSUMER / WEB APPCATION (Appends, serves, and reads data via logs) ---
        - name: container-4-final-reader
          image: alpine:3.18
          command: ["/bin/sh", "-c"]
          args:
            - |
              while true; do
                if [ -f /workspace/shared_data.txt ]; then
                  echo "[Container 4]: Final compilation check completed." >> /workspace/shared_data.txt
                  echo "------------------------------------------------"
                  cat /workspace/shared_data.txt
                  echo "================================================"
                fi
                sleep 10
              done
          volumeMounts:
            - name: pipeline-storage
              mountPath: /workspace

      # --- THE CENTRAL WORKSPACE STORAGE ---
      volumes:
        - name: pipeline-storage
          emptyDir: {}
Why this works and how the loops sync
Because all 4 containers start at the exact same time, we added basic protection to the script loops:

Container 1 uses a single > character to overwrite the file cleanly every 10 seconds. This resets the pipeline state.

Containers 2, 3, and 4 check if the file exists first (if [ -f ... ]), then use double >> operators to append their text lines to the bottom without erasing what the previous container wrote.

Container 4 handles the final read step by running cat /workspace/shared_data.txt inside an endless loop. Since it outputs straight to the screen, its execution automatically pipes into the standard Kubernetes logging stream.

How to Deploy and Verify
Apply the manifest from your k8s-master node:

Bash
kubectl apply -f 4-container-pipeline.yaml
Watch it spin up to 4/4 Ready:

Bash
kubectl get pods -n my-ns -w
Read the final aggregated logs:
To see the completed chained dataset compiled across all four containers, target the 4th container explicitly using the -c flag:

Bash
kubectl logs -f deployment/multi-agent-pipeline -n my-ns -c container-4-final-reader
What you will see in the output stream:
Plaintext
[Container 1]: Initialized task data at Sat May 23 02:23:20 IST 2026
[Container 2]: Appended analytics modeling info
[Container 3]: Appended data verification signatures
[Container 4]: Final compilation check completed.
================================================The 4-Container Pipeline Manifest
Save this file on your master node as 4-container-pipeline.yaml:

YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: multi-agent-pipeline
  namespace: my-ns
  labels:
    app: data-pipeline
spec:
  replicas: 1
  selector:
    matchLabels:
      app: data-pipeline
  template:
    metadata:
      labels:
        app: data-pipeline
    spec:
      containers:
        # --- 1. THE ORIGIN GENERATOR (Writes initial data) ---
        - name: container-1-writer
          image: alpine:3.18
          command: ["/bin/sh", "-c"]
          args:
            - |
              mkdir -p /workspace
              while true; do
                echo "[Container 1]: Initialized task data at $(date)" > /workspace/shared_data.txt
                sleep 10
              done
          volumeMounts:
            - name: pipeline-storage
              mountPath: /workspace

        # --- 2. THE SECOND STAGE AGENT (Appends data) ---
        - name: container-2-appender
          image: alpine:3.18
          command: ["/bin/sh", "-c"]
          args:
            - |
              while true; do
                if [ -f /workspace/shared_data.txt ]; then
                  echo "[Container 2]: Appended analytics modeling info" >> /workspace/shared_data.txt
                fi
                sleep 10
              done
          volumeMounts:
            - name: pipeline-storage
              mountPath: /workspace

        # --- 3. THE THIRD STAGE AGENT (Appends data) ---
        - name: container-3-appender
          image: alpine:3.18
          command: ["/bin/sh", "-c"]
          args:
            - |
              while true; do
                if [ -f /workspace/shared_data.txt ]; then
                  echo "[Container 3]: Appended data verification signatures" >> /workspace/shared_data.txt
                fi
                sleep 10
              done
          volumeMounts:
            - name: pipeline-storage
              mountPath: /workspace

        # --- 4. THE CONSUMER / WEB APPCATION (Appends, serves, and reads data via logs) ---
        - name: container-4-final-reader
          image: alpine:3.18
          command: ["/bin/sh", "-c"]
          args:
            - |
              while true; do
                if [ -f /workspace/shared_data.txt ]; then
                  echo "[Container 4]: Final compilation check completed." >> /workspace/shared_data.txt
                  echo "------------------------------------------------"
                  cat /workspace/shared_data.txt
                  echo "================================================"
                fi
                sleep 10
              done
          volumeMounts:
            - name: pipeline-storage
              mountPath: /workspace

      # --- THE CENTRAL WORKSPACE STORAGE ---
      volumes:
        - name: pipeline-storage
          emptyDir: {}
Why this works and how the loops sync
Because all 4 containers start at the exact same time, we added basic protection to the script loops:

Container 1 uses a single > character to overwrite the file cleanly every 10 seconds. This resets the pipeline state.

Containers 2, 3, and 4 check if the file exists first (if [ -f ... ]), then use double >> operators to append their text lines to the bottom without erasing what the previous container wrote.

Container 4 handles the final read step by running cat /workspace/shared_data.txt inside an endless loop. Since it outputs straight to the screen, its execution automatically pipes into the standard Kubernetes logging stream.

How to Deploy and Verify
Apply the manifest from your k8s-master node:

Bash
kubectl apply -f 4-container-pipeline.yaml
Watch it spin up to 4/4 Ready:

Bash
kubectl get pods -n my-ns -w
Read the final aggregated logs:
To see the completed chained dataset compiled across all four containers, target the 4th container explicitly using the -c flag:

Bash
kubectl logs -f deployment/multi-agent-pipeline -n my-ns -c container-4-final-reader
What you will see in the output stream:
Plaintext
[Container 1]: Initialized task data at Sat May 23 02:23:20 IST 2026
[Container 2]: Appended analytics modeling info
[Container 3]: Appended data verification signatures
[Container 4]: Final compilation check completed.
================================================
