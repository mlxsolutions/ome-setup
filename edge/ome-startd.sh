#!/bin/bash
OME_DOCKER_HOME="/opt/ovenmediaengine"
OME_LOG_FILE="$OME_DOCKER_HOME/logs/ovenmediaengine.log"
OME_TYPE="edge"


# --- Run OME Docker container ---
echo "Checking environment variables...:"
if [ -z "$OME_HOST_IP" ] || [ -z "$OME_DOCKER_HOME" ]; then
  echo "❌ Missing required environment variables. Please set OME_HOST_IP, OME_DOCKER_HOME."
  exit 1
fi

# make sure that is not running
echo "🧹Stopping and removing any existing OME container..."
docker stop ome
docker rm ome

# --- Run OME Docker container ---
echo "🚀 Launching OvenMediaEngine..."


# RUN
docker run -d --name ome \
  -e OME_HOST_IP="$OME_HOST_IP" \
  -v "$OME_DOCKER_HOME/conf":/opt/ovenmediaengine/bin/origin_conf \
  -v "$OME_DOCKER_HOME/logs":/var/log/ovenmediaengine \
  -p 1935:1935 \
  -p 9999:9999/udp \
  -p 9000:9000 \
  -p 3333:3333 \
  -p 3334:3334 \
  -p 4333:4333 \
  -p 4334:4334 \
  -p 3478:3478 \
  -p 8081:8081 \
  -p 8082:8082 \
  -p 10000-10009:10000-10009/udp \
  airensoft/ovenmediaengine:latest



echo "✅ OME is up and running! Check logs with:"
echo "Ingress:"
echo "  wss://$OME_HOST_IP:3334/<app name>/<stream name>?direction=send&transport=tcp"
echo "  https://$OME_HOST_IP:3334/<app name>/<stream name>?direction=whip&transport=tcp"
echo "Playback:"
echo "  wss://$OME_HOST_IP:3334/<Application name>/<Stream name>"

echo "Logs:"
echo "  $OME_LOG_FILE"
echo "To view logs in real-time, run:"
echo "  tail -f $OME_DOCKER_HOME/logs/ovenmediaengine.log"
OME_TYPE="edge"