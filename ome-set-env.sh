#!/bin/bash
set -e
# Check if the script is run with root privileges
if [ "$(id -u)" -ne 0 ]; then
	echo "❌ This script must be run as root. Use 'sudo' to run it."
	exit 1
fi

# Check if the required arguments are provided
if [ -z "$OME_DOMAIN" ]; then
    echo "Usage: $0 <domain> <redis_auth> <admission-webhook-secret> <api_access_token>"
    exit 1
fi

# Input arguments
OME_HOST_IP="$1"
OME_DOMAIN="$1"
OME_REDIS_AUTH="$2"
OME_ADMISSION_WEBHOOK_SECRET="$3"
OME_API_ACCESS_TOKEN="$4"


# Static values
OME_DOCKER_HOME="/opt/ovenmediaengine"
OME_LOG_FILE="/opt/ovenmediaengin/logs/ovenmediaengine.log"

BASHRC="$HOME/.bashrc"

echo "Persisting OME environment variables to $BASHRC..."

# Helper function to export if not already in file
append_export() {
  local VAR=$1
  local VAL=$2
  local LINE="export $VAR=\"$VAL\""
  grep -q "^export $VAR=" "$BASHRC" || echo "$LINE" >> "$BASHRC"
}

# List of variables to export
append_export "OME_HOST_IP" "$OME_HOST_IP"
append_export "OME_DOMAIN" "$OME_DOMAIN"
append_export "OME_REDIS_AUTH" "$OME_REDIS_AUTH"
append_export "OME_ADMISSION_WEBHOOK_SECRET" "$OME_ADMISSION_WEBHOOK_SECRET"
append_export "OME_API_ACCESS_TOKEN" "$OME_API_ACCESS_TOKEN"
append_export "OME_DOCKER_HOME" "$OME_DOCKER_HOME"
append_export "OME_LOG_FILE" "$OME_LOG_FILE"

echo "✅ Done. Run 'source ~/.bashrc' or restart your shell to apply."