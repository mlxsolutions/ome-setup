
#!/bin/bash

set -e

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
Environment=OME_REDIS_AUTH=$OME_REDIS_AUTH
Environment=OME_DOCKER_HOME=$OME_DOCKER_HOME
Environment=OME_LOG_FILE=$OME_LOG_FILE
ExecStart=$OME_DOCKER_HOME/ome-startd.sh
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

sudo chmod 644 "$SERVICE_FILE"
sudo systemctl daemon-reload
sudo systemctl enable ome.service

echo "✅ systemd service 'ome.service' has been created and enabled to run at startup."
