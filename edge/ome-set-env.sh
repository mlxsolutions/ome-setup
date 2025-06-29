#!/bin/bash

# Check for root privileges for /etc/environment
if [ "$(id -u)" -ne 0 ]; then
  echo "⚠️  This script must be run with sudo to modify /etc/environment"
  echo "Try: sudo $0"
  exit 1
fi

# Input arguments
OME_HOST_IP="$1"

# Static values
DEPLOY_HOOK="/etc/letsencrypt/renewal-hooks/deploy/ome-reload.sh"
OME_DOCKER_HOME="/opt/ovenmediaengine"
OME_LOG_FILE="/opt/ovenmediaengine/logs/ovenmediaengine.log"
OME_TYPE="edge"

# Check if the required arguments are provided
if [ -z "$OME_HOST_IP" ] || [ -z "$OME_REDIS_AUTH" ]; then
  echo "❌ Missing required environment variables. Please set OME_HOST_IP, OME_REDIS_AUTH."
  exit 1
fi

# Define environment variables
declare -A ENV_VARS=(
  ["OME_HOST_IP"]="$OME_HOST_IP"
  ["OME_LOG_FILE"]="$OME_LOG_FILE"
  ["OME_TYPE"]="$OME_TYPE"
  ["OME_DOCKER_HOME"]="$OME_DOCKER_HOME"
)

# 1. Append to ~/.bashrc and ~/.profile
for FILE in "/home/$SUDO_USER/.bashrc" "/home/$SUDO_USER/.profile"; do
  echo "🔧 Updating $FILE ..."
  for VAR in "${!ENV_VARS[@]}"; do
    sed -i "/^export $VAR=/d" "$FILE"
    echo "export $VAR=\"${ENV_VARS[$VAR]}\"" >> "$FILE"
  done
done

# 2. Update /etc/environment (no 'export' here)
echo "🔧 Updating /etc/environment ..."
for VAR in "${!ENV_VARS[@]}"; do
  if grep -q "^$VAR=" /etc/environment; then
    sed -i "s|^$VAR=.*|$VAR=\"${ENV_VARS[$VAR]}\"|" /etc/environment
  else
    echo "$VAR=\"${ENV_VARS[$VAR]}\"" >> /etc/environment
  fi
done

echo "✅ Environment variables added to:"
echo "- ~/.bashrc"
echo "- ~/.profile"
echo "- /etc/environment"

echo "📎 Remember:"
echo "- Run: source ~/.bashrc or log out/in to apply"
echo "- Reboot to apply /etc/environment globally"