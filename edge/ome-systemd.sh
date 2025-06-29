
#!/bin/bash

set -e

OME_DOCKER_HOME="/opt/ovenmediaengine"
OME_LOG_FILE="$OME_DOCKER_HOME/logs/ovenmediaengine.log"
OME_TYPE="edge"
OME_HOST_IP="$1"

# Check if the required arguments are provided
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <domain> "
  exit 1
fi


# --- Setup systemd service for OME ---
echo "🛠️ Setting up systemd service for OME..."

SERVICE_FILE="/etc/systemd/system/ome.service"
cat <<EOF | sudo tee "$SERVICE_FILE" > /dev/null
[Unit]
Description=Start OvenMediaEngine Docker container
After=network.target docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=true
Environment=OME_HOST_IP=$OME_HOST_IP
Environment=OME_DOCKER_HOME=$OME_DOCKER_HOME
ExecStart=$OME_DOCKER_HOME/ome-startd.sh
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

sudo chmod 644 "$SERVICE_FILE"
sudo systemctl daemon-reload
sudo systemctl enable ome.service

echo "✅ systemd service 'ome.service' has been created and enabled to run at startup."
