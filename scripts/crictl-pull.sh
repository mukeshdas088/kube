#!/bin/bash

# --- CHECK FOR SUDO PRIVILEGES ---
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script with sudo privileges."
  echo "Example: sudo ./pull-interactive.sh"
  exit 1
fi

echo "================================================"
echo "☸️  Interactive Kubernetes crictl Image Puller"
echo "================================================"

# --- READ INPUT FROM USER ---
# The -p flag prompts the user, and the text is saved into the variable 'IMAGE_NAME'
read -p "👉 Enter the image name to download (e.g., nginx, alpine:3.18): " IMAGE_NAME

# Check if the user accidentally pressed enter without typing anything
if [ -z "$IMAGE_NAME" ]; then
  echo "❌ Error: Image name cannot be empty!"
  exit 1
fi

echo "------------------------------------------------"
echo "📥 Initializing pull request for: $IMAGE_NAME..."
echo "------------------------------------------------"

# --- EXECUTE THE CRICTL PULL ---
sudo crictl pull "$IMAGE_NAME"

# Check the exit status of the crictl command
if [ $? -eq 0 ]; then
  echo ""
  echo "✅ Successfully downloaded and cached: $IMAGE_NAME"
else
  echo ""
  echo "❌ Failed to download: $IMAGE_NAME"
  echo "💡 Tip: Verify the name/tag or check your mobile hotspot connection."
fi

echo "------------------------------------------------"
echo "🎉 Process finished!"
