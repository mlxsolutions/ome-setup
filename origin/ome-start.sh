#!/bin/bash

#PUBLIC_IP=$(curl -s checkip.amazonaws.com | awk '{print $1}')
#OME_HOST_IP=$(hostname -I | awk '{print $1}')
#OME_DOCKER_HOME="/opt/ovenmediaengine"
#OME_DOMAIN="live-origin-eu.mlx.solutions"



# --- Run OME Docker container ---
echo "🚀 Launching OvenMediaEngine..."

# clean the log
sudo cp "$OME_LOG_FILE" "$OME_LOG_FILE.$(date +%Y%m%d%H%M%S)"
sudo rm -f "$OME_LOG_FILE"

# RUN
sudo docker run -d --name ome \
  -e OME_HOST_IP="$OME_HOST_IP" \
  -e OME_REDIS_AUTH="$OME_REDIS_AUTH" \
  -e OME_ADMISSION_WEBHOOK_SECRET="$OME_ADMISSION_WEBHOOK_SECRET" \
  -e OME_API_ACCESS_TOKEN="$OME_API_ACCESS_TOKEN" \
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
  -p 20080:20080 \
  -p 20081:20081 \
  -p 10000-10009:10000-10009/udp \
  airensoft/ovenmediaengine:latest



echo "✅ OME is up and running! Check logs with:"
echo "tail -f $OME_DOCKER_HOME/logs/ovenmediaengine.log"
echo "Ingress:"
echo "  wss://$OME_HOST_IP:3334/<app name>/<stream name>?direction=send&transport=tcp"
echo "  https://$OME_HOST_IP:3334/<app name>/<stream name>?direction=whip&transport=tcp"
echo "Playback:"
echo "  wss://$OME_HOST_IP:3334/<Application name>/<Stream name>"

sudo tail -f $OME_DOCKER_HOME/logs/ovenmediaengine.log
# https://docs.ovenmediaengine.com/streaming/webrtc-publishing