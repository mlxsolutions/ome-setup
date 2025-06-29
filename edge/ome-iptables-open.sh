#!/bin/bash

set -e

echo "📦 Installing iptables-persistent if not already installed..."
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y iptables-persistent

echo "🔐 Configuring iptables rules..."

# Allow SSH
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Open TCP ports
for port in 80 443 9000 1935 3333 3334 4334 4333 3478 8081 8082 20080 20081; do
    iptables -A INPUT -p tcp --dport $port -j ACCEPT
done

# Open specific UDP ports
for port in 9999 4000; do
    iptables -A INPUT -p udp --dport $port -j ACCEPT
done

# Open UDP port range
iptables -A INPUT -p udp --dport 10000:10009 -j ACCEPT

# Accept established and related connections
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow loopback interface
iptables -A INPUT -i lo -j ACCEPT

# Drop all other traffic
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

echo "💾 Saving iptables rules..."
netfilter-persistent save

echo "✅ Firewall rules configured and saved successfully."