# ome-setup
Oven Media Engine Public Repo

# Common commands

`sudo bash ./ome-start.sh`

`sudo bash ./ome-stop.sh`

`sudo tail -f /opt/ovenmediaengine/logs/ovenmediaengine.log`

`sudo curl -L "https://github.com/mlxsolutions/ome-setup/raw/main/${OME_TYPE}/Server.xml" -o "$OME_DOCKER_HOME/conf/Server.xml"`

`sudo nano $OME_DOCKER_HOME/conf/Server.xml`

`sudo nano $OME_DOCKER_HOME/conf/Logger.xml`
---
# Origin

## Installation
```bash
export OME_HOST_IP="FQDN, NOT THE IP"
export OME_REDIS_AUTH="myredispassword"
export OME_ADMISSION_WEBHOOK_SECRET="webhooksecret"
export OME_API_ACCESS_TOKEN="managedapitoken"
export OME_TYPE="origin"
```

```bash
sudo curl -L "https://raw.githubusercontent.com/mlxsolutions/ome-setup/refs/heads/main/origin/ome-install.sh" -o ome-install.sh
sudo chmod + ome-install.sh
sudo bash ./ome-install.sh $OME_HOST_IP $OME_REDIS_AUTH $OME_ADMISSION_WEBHOOK_SECRET $OME_API_ACCESS_TOKEN
```

---
# Edge

## Installation

```bash
export OME_HOST_IP="FQDN, NOT THE IP"
export OME_REDIS_AUTH="myredispassword"
export OME_TYPE="edge"
```

```bash
sudo curl -L "https://raw.githubusercontent.com/mlxsolutions/ome-setup/refs/heads/main/edge/ome-install.sh" -o ome-install.sh
sudo chmod + ome-install.sh
sudo bash ./ome-install.sh $OME_HOST_IP $OME_REDIS_AUTH
```


