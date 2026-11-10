#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq curl unzip jq openssl >/dev/null 2>&1
bash -c "$(curl -L -s https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install >/dev/null 2>&1
UUID=$(cat /proc/sys/kernel/random/uuid)
OUT=$(/usr/local/bin/xray x25519)
PRIV=$(echo "$OUT" | grep -iE "private" | awk '{print $NF}')
PUB=$(echo "$OUT" | grep -iE "public" | awk '{print $NF}')
SID=$(openssl rand -hex 8)
mkdir -p /usr/local/etc/xray
cat > /usr/local/etc/xray/config.json <<JSON
{
  "log": {"loglevel": "warning"},
  "inbounds": [{
    "listen": "0.0.0.0",
    "port": 8443,
    "protocol": "vless",
    "settings": {
      "clients": [{"id": "$UUID", "flow": "xtls-rprx-vision"}],
      "decryption": "none"
    },
    "streamSettings": {
      "network": "tcp",
      "security": "reality",
      "realitySettings": {
        "show": false,
        "dest": "www.microsoft.com:443",
        "xver": 0,
        "serverNames": ["www.microsoft.com"],
        "privateKey": "$PRIV",
        "shortIds": ["$SID"]
      }
    },
    "sniffing": {"enabled": true, "destOverride": ["http","tls","quic"]}
  }],
  "outbounds": [{"protocol": "freedom", "tag": "direct"}]
}
JSON
systemctl enable xray >/dev/null 2>&1
systemctl restart xray
sleep 2
echo "=== RESULT ==="
echo "UUID=$UUID"
echo "PUB=$PUB"
echo "SID=$SID"
echo "PORT=8443"
echo "STATUS=$(systemctl is-active xray)"
echo "IP=$(curl -s -m 5 https://api.ipify.org || echo '')"
