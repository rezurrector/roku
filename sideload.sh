#!/bin/bash

# === 🛠 Helper: Pretty print ===
info() { echo -e "\033[1;34mℹ️  $1\033[0m"; }
success() { echo -e "\033[1;32m✅ $1\033[0m"; }
error() { echo -e "\033[1;31m❌ $1\033[0m"; }

# === 🚦 Preflight check ===
# Ensure the required environment variables are set
ROKU_DEV_IP=""   # Replace with your Roku device IP
ROKU_USER=""           # Replace with your Roku developer username
ROKU_PASS=""              # Replace with your Roku developer password

# === Validate variables ===
: "${ROKU_DEV_IP:?$(error "ROKU_DEV_IP not set")}"
: "${ROKU_USER:?$(error "ROKU_USER not set")}"
: "${ROKU_PASS:?$(error "ROKU_PASS not set")}"

# === Define the ZIP file path ===
APP_ZIP_PATH="./app.zip"  # Path to your ZIP file to be sideloaded

# === Wait for Roku ===
until curl -s --connect-timeout 2 http://$ROKU_DEV_IP:8060 | grep -q "<friendlyName>"; do
  echo "Roku not ready yet at $ROKU_DEV_IP:8060..."
  sleep 1
done

echo "Roku is ready!"

# === Sideload function ===
sideload() {
  info "Zipping Roku app..."
  zip -q -r $APP_ZIP_PATH * -x "*.git*" -x "app.zip" -x "sideload.sh"

  info "Uploading (sideloading) to Roku..."
  curl -s -u "$ROKU_USER:$ROKU_PASS" -F "archive=@$APP_ZIP_PATH" -F "passwd=" http://$ROKU_DEV_IP/plugin_install > /dev/null

  success "Sideload complete!"

  # === Optional auto-launch channel ===
  info "Launching sideloaded channel..."
  curl -s -d '' http://$ROKU_DEV_IP:8060/launch/dev > /dev/null
  success "Channel launched on Roku!"
}

# === Initial sideload ===
sideload

# === Watch for file changes and trigger sideload ===
info "Watching for changes... (Ctrl+C to stop)"
find . -type f \( -name "*.brs" -o -name "*.xml" -o -name "*.jpg" -o -name "*.png" -o -name "*.ttf" \) | entr -r bash -c './sideload.sh && sideload'
