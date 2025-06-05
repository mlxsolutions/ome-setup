#!/bin/bash

# Check for root privileges for /etc/environment
if [ "$(id -u)" -ne 0 ]; then
  echo "⚠️  This script must be run with sudo to modify /etc/environment"
  echo "Try: sudo $0"
  exit 1
fi

# Input arguments
OME_HOST_IP="$1"
OME_REDIS_AUTH="$2"
OME_ADMISSION_WEBHOOK_SECRET="$3"
OME_API_ACCESS_TOKEN="$4"

# Static values
DEPLOY_HOOK="/etc/letsencrypt/renewal-hooks/deploy/ome-reload.sh"
OME_DOCKER_HOME="/opt/ovenmediaengine"
OME_LOG_FILE="/opt/ovenmediaengine/logs/ovenmediaengine.log"
OME_TYPE="origin"

# Check if the required arguments are provided
if [ "$#" -ne 4 ]; then
  echo "Usage: $0   <domain> <redis_auth> <admission_webhook_secret> <api_access_token>"
  exit 1
fi

# Define environment variables
declare -A ENV_VARS=(
  ["OME_HOST_IP"]="$OME_HOST_IP"
  ["OME_REDIS_AUTH"]="$OME_REDIS_AUTH"
  ["OME_LOG_FILE"]="$OME_LOG_FILE"
  ["OME_ADMISSION_WEBHOOK_SECRET"]="$OME_ADMISSION_WEBHOOK_SECRET"
  ["OME_API_ACCESS_TOKEN"]="$OME_API_ACCESS_TOKEN"
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