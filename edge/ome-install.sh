#!/bin/bash
set -e
# Check if the script is run with root privileges
if [ "$(id -u)" -ne 0 ]; then
	echo "❌ This script must be run as root. Use 'sudo' to run it."
	exit 1
fi

source ~/.bashrc

# Input arguments
OME_HOST_IP="$1"
OME_REDIS_AUTH="$2"

# Static values
DEPLOY_HOOK="/etc/letsencrypt/renewal-hooks/deploy/ome-reload.sh"
OME_DOCKER_HOME="/opt/ovenmediaengine"
OME_LOG_FILE="/opt/ovenmediaengine/logs/ovenmediaengine.log"
OME_TYPE="edge"

# Check if the required arguments are provided
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <domain> <redis_auth>"
  exit 1
fi

# -- set environment variables if not set --
echo "✅ Adding environment variables.."
# Remove previous block if any
sed -i '/# OME ENV START/,/# OME ENV END/d' ~/.bashrc

cat >> ~/.bashrc <<EOF
# OME ENV START
export OME_DOCKER_HOME=$OME_DOCKER_HOME
export OME_HOST_IP=$OME_HOST_IP
export OME_LOG_FILE=$OME_LOG_FILE
export OME_TYPE=$OME_TYPE
export OME_REDIS_AUTH=$OME_REDIS_AUTH
# OME ENV END
EOF
echo "✅ Environment block added to ~/.bashrc"



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
echo "🔐 Requesting Let's Encrypt TLS cert for $OME_HOST_IP..."
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
cp /etc/letsencrypt/live/$OME_HOST_IP/fullchain.pem "$OME_DOCKER_HOME/conf/fullchain.pem"
chmod 640 "$OME_DOCKER_HOME/conf/cert.key"

# --- fetch the Server.xml and Logger.xml
echo "📥 Fetching OME config files..."
curl -L "https://github.com/mlxsolutions/ome-setup/raw/main/${OME_TYPE}/Server.xml" -o "$OME_DOCKER_HOME/conf/Server.xml"
curl -L "https://github.com/mlxsolutions/ome-setup/raw/main/${OME_TYPE}/Logger.info.xml" -o "$OME_DOCKER_HOME/conf/Logger.xml"
curl -L "https://github.com/mlxsolutions/ome-setup/raw/main/${OME_TYPE}/Logger.debug.xml" -o "$OME_DOCKER_HOME/conf/Logger.debug.xml"
curl -L "https://github.com/mlxsolutions/ome-setup/raw/main/${OME_TYPE}/ome-start.sh" -o "./ome-start.sh"
curl -L "https://github.com/mlxsolutions/ome-setup/raw/main/${OME_TYPE}/ome-stop.sh" -o "./ome-stop.sh"
# Make scripts executable
sudo chmod +x ./ome-start.sh
sudo chmod +x ./ome-stop.sh

# --- Copy OME config files from Docker image ---
sudo docker run -d --name tmp-ome airensoft/ovenmediaengine:latest
sudo docker cp tmp-ome:/opt/ovenmediaengine/bin/${OME_TYPE}_conf/Server.xml $OME_DOCKER_HOME/conf/Server.template.xml
sudo docker rm -f tmp-ome

# --- END --
echo "🙌 🎉 Docker, Lets Encrypt and OME installed. "
echo "Please run 'source ~/.bashrc' to apply the environment variables."
echo "Thereafter you can now start OME with sudo bash ./ome-start.sh"
