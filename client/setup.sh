#!/usr/bin/env bash
# Bring up an Xray VLESS+Reality client that exposes a local SOCKS5.
# Source the credentials file the server wrote, e.g.:
#   scp root@SERVER:/root/.xray/credentials /tmp/xray.env
#   . /tmp/xray.env && ./setup.sh
# Or set the vars inline:
#   SERVER_IP=1.2.3.4 PORT=443 DEST=www.apple.com \
#   UUID=... PUBLIC_KEY=... SHORT_ID=... ./setup.sh
set -euo pipefail

: "${SERVER_IP:?set SERVER_IP}"
: "${UUID:?set UUID}"
: "${PUBLIC_KEY:?set PUBLIC_KEY}"
: "${SHORT_ID:?set SHORT_ID}"
PORT="${PORT:-443}"
DEST="${DEST:-www.apple.com}"
SOCKS_PORT="${SOCKS_PORT:-1080}"
LISTEN="${LISTEN:-0.0.0.0}"
XRAY_CONFIG="/usr/local/etc/xray/config.json"

[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 1; }

if ! command -v xray >/dev/null; then
  echo ">> installing xray"
  bash -c "$(curl -fsSL https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
fi

install -d -m 700 /usr/local/etc/xray
cat >"$XRAY_CONFIG" <<JSON
{
  "log": {"loglevel": "warning"},
  "inbounds": [{
    "tag": "socks-in",
    "port": ${SOCKS_PORT},
    "listen": "${LISTEN}",
    "protocol": "socks",
    "settings": {"udp": true, "auth": "noauth"}
  }],
  "outbounds": [{
    "protocol": "vless",
    "settings": {
      "vnext": [{
        "address": "${SERVER_IP}",
        "port": ${PORT},
        "users": [{
          "id": "${UUID}",
          "flow": "xtls-rprx-vision",
          "encryption": "none"
        }]
      }]
    },
    "streamSettings": {
      "network": "tcp",
      "security": "reality",
      "realitySettings": {
        "serverName": "${DEST}",
        "fingerprint": "chrome",
        "publicKey": "${PUBLIC_KEY}",
        "shortId": "${SHORT_ID}"
      }
    }
  }]
}
JSON
chmod 600 "$XRAY_CONFIG"

systemctl enable --now xray >/dev/null
systemctl restart xray
sleep 1
if ! systemctl is-active --quiet xray; then
  journalctl -u xray -n 40 --no-pager
  exit 1
fi

echo ">> SOCKS5 on ${LISTEN}:${SOCKS_PORT}"
echo "   test:  curl --socks5 127.0.0.1:${SOCKS_PORT} https://ifconfig.me"
echo "          (should print ${SERVER_IP}, not your local egress)"
