#!/bin/bash
set -e
# Check if the script is run with root privileges
if [ "$(id -u)" -ne 0 ]; then
	echo "❌ This script must be run as root. Use 'sudo' to run it."
	exit 1
fi


OME_HOST_IP="$1"

# Check if the required arguments are provided
if [ -z "$OME_HOST_IP" ]; then
  echo "Usage: $0 <domain>"
  echo "Example: $0 example.com"
  exit 1
fi

DEPLOY_HOOK="/etc/letsencrypt/renewal-hooks/deploy/ome-reload.sh"
OME_DOCKER_HOME="/opt/ovenmediaengine"
OME_LOG_FILE="/opt/ovenmediaengine/logs/ovenmediaengine.log"

# -- set environment variables if not set --
echo "✅ Adding environment variables.."
echo "export OME_DOCKER_HOME=$OME_DOCKER_HOME" >> ~/.bashrc
echo "export OME_HOST_IP=$OME_HOST_IP" >> ~/.bashrc
echo "export OME_LOG_FILE=$OME_LOG_FILE" >> ~/.bashrc


# --- open firewall ports ---
echo "🔒 Configuring firewall rules..."

sudo ufw allow OpenSSH
sudo ufw --force enable

for port in 80 443 9000 1935 3333 3334 4334 4333 3478 8081 8082 20080 20081; do
  sudo ufw allow ${port}/tcp
done

sudo ufw allow 9999/udp
sudo ufw allow 4000/udp
sudo ufw allow 10000:10009/udp

echo "✅ OME ports opened via UFW."


# --- Install Docker if not present ---
if ! command -v docker &>/dev/null; then
  echo "🚀 Installing Docker..."
  sudo apt update
  sudo apt install -y ca-certificates curl gnupg lsb-release
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt update
  sudo apt install -y docker-ce docker-ce-cli containerd.io
  sudo systemctl enable docker
  sudo systemctl start docker
fi

# --- Install Certbot if not present ---
if ! command -v certbot &>/dev/null; then
  echo "🔐 Installing Certbot..."
  sudo apt update
  sudo apt install -y certbot
fi

# --- Setup OME directories ---
echo "📁 Creating OME home at $OME_DOCKER_HOME"
sudo mkdir -p "$OME_DOCKER_HOME/conf" "$OME_DOCKER_HOME/logs"
sudo chgrp -R docker "$OME_DOCKER_HOME"
sudo chmod -R 775 "$OME_DOCKER_HOME"


# --- Obtain Let's Encrypt Cert ---
echo "🔐 Requesting Let's Encrypt TLS cert for $OME_..."
sudo systemctl stop nginx 2>/dev/null || true  # stop nginx if present
sudo certbot certonly --standalone --non-interactive --agree-tos -m owner@mlx.solutions -d "$OME_HOST_IP"

# --- retart nginx if it was running ---
if systemctl is-active --quiet nginx; then
  echo "🔁 Restarting nginx..."
  sudo systemctl start nginx
fi

# --- Check if certs were created ---
if [ ! -f "/etc/letsencrypt/live/$OME_HOST_IP/fullchain.pem" ]; then
  echo "❌ TLS certificate for $OME_HOST_IP not found. Certbot may have failed."
  exit 1
fi

# --- Create deploy hook for automatic cert copy ---
echo "✅ Creating deploy hook for automatic copy + nginx reload"
cat > "$DEPLOY_HOOK" <<EOF
#!/bin/bash
# Auto-deploy hook for $OME_HOST_IP

SRC="/etc/letsencrypt/live/\$OME_HOST_IP"
DEST="$OME_DOCKER_HOME/conf"
cp "\$SRC/cert.pem" "\$DEST/cert.crt"
cp "\$SRC/privkey.pem" "\$DEST/cert.key"
cp "\$SRC/chain.pem" "\$DEST/cert.ca-bundle"
chmod 640 "\$DEST/cert.key"
docker restart ome
EOF

chmod +x "$DEPLOY_HOOK"

echo "✅ Testing renewal dry-run..."
certbot renew --dry-run

# --- Link certs into OME conf ---
echo "Copying TLS certs into OME config..."
cp /etc/letsencrypt/live/$OME_HOST_IP/cert.pem "$OME_DOCKER_HOME/conf/cert.crt"
cp /etc/letsencrypt/live/$OME_HOST_IP/privkey.pem "$OME_DOCKER_HOME/conf/cert.key"
cp /etc/letsencrypt/live/$OME_HOST_IP/chain.pem "$OME_DOCKER_HOME/conf/cert.ca-bundle"
#cp /etc/letsencrypt/live/$OME_DOMAIN/fullchain.pem "$OME_DOCKER_HOME/conf/cert.ca-bundle"
chmod 640 "$OME_DOCKER_HOME/conf/cert.key"

# --- fetch the Server.xml and Logger.xml
echo "📥 Fetching OME config files..."
curl -L "https://mlxsolutions-pub-conf.s3.eu-west-1.amazonaws.com/ome/$OME_DOMAIN/Server.xml" -o "$OME_DOCKER_HOME/conf/Server.xml"

# -- fetch some config scripts --
curl -L "https://mlxsolutions-pub-conf.s3.eu-west-1.amazonaws.com/ome/scripts/ome-start.sh" -o "./ome-start.sh"
curl -L "https://mlxsolutions-pub-conf.s3.eu-west-1.amazonaws.com/ome/scripts/ome-stop.sh" -o "./ome-stop.sh"
curl -L "https://mlxsolutions-pub-conf.s3.eu-west-1.amazonaws.com/ome/scripts/ome-restart.sh" -o "./ome-restart.sh"
# Make scripts executable
sudo chmod +x ./ome-start.sh
sudo chmod +x ./ome-stop.sh
sudo chmod +x ./ome-restart.sh

# --- Copy OME config files from Docker image ---
sudo docker run -d --name tmp-ome airensoft/ovenmediaengine:latest
sudo docker cp tmp-ome:/opt/ovenmediaengine/bin/origin_conf/Server.xml $OME_DOCKER_HOME/conf/Server.template.origin.xml
sudo docker cp tmp-ome:/opt/ovenmediaengine/bin/edge_conf/Server.xml $OME_DOCKER_HOME/conf/Server.template.edge.xml
sudo docker cp tmp-ome:/opt/ovenmediaengine/bin/origin_conf/Logger.xml $OME_DOCKER_HOME/conf/Logger.xml
sudo docker rm -f tmp-ome
sudo docker rm -f tmp-ome

# --- END --
echo "🙌 🎉 Docker, Lets Encrypt and OME installed. "
echo "You can now start OME with sudo bash ./ome-start.sh"
s