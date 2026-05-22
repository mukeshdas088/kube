#!/bin/sh

# --- 1. CHECK FOR ROOT PRIVILEGES ---
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ Error: This script must be run with sudo/root privileges."
    echo "Usage: sudo ./delete.sh"
    exit 1
fi

echo "================================================"
echo "☸️  POSIX crictl Image Lifecycle Cleaner"
echo "================================================"

# --- 2. CHECK IF CRICTL IS INSTALLED AND RUNNING ---
# 'type' is the POSIX standard way to check if a command exists
if ! type crictl > /dev/null 2>&1; then
    echo "❌ Error: 'crictl' command utility not found on this system."
    exit 1
fi

# Verify if the containerd/CRI socket runtime is actively responding
if ! crictl info > /dev/null 2>&1; then
    echo "❌ Error: 'crictl' is installed, but the container runtime socket is down."
    echo "         Check if containerd or cri-o service is running."
    exit 1
fi

echo "✅ crictl runtime engine is active and running."
echo "------------------------------------------------"

# --- 3. READ THE IMAGE TARGET FROM THE USER ---
printf "👉 Enter the image name or ID to delete: "
read -r TARGET_IMAGE

# Validate input is not empty
if [ -z "$TARGET_IMAGE" ]; then
    echo "❌ Error: Image target input cannot be empty!"
    exit 1
fi

echo "------------------------------------------------"
echo "🔍 Searching local cache for: $TARGET_IMAGE..."

# --- 4. CHECK IF THE IMAGE PERSISTS IN CACHE ---
# 'crictl images -q' returns the unique hash if the image exists, empty if it doesn't
IMAGE_ID=$(crictl images -q "$TARGET_IMAGE" 2>/dev/null)

if [ -z "$IMAGE_ID" ]; then
    echo "ℹ️  The image '$TARGET_IMAGE' does not exist in the local cache."
    echo "   Nothing to delete."
    echo "------------------------------------------------"
    exit 0
fi

echo "🎯 Found target cache match! ID: $IMAGE_ID"

# --- 5. EXECUTE THE TRUCATED DELETE ---
echo "🗑️  Removing image from worker node storage..."
if crictl rmi "$IMAGE_ID" > /dev/null 2>&1; then
    echo "✅ Success: Image '$TARGET_IMAGE' has been cleanly deleted."
else
    echo "❌ Error: Failed to delete image. It might be locked by an active Pod container."
    echo "         Run 'kubectl get pods -A' to ensure no pods are running it."
fi

echo "------------------------------------------------"
