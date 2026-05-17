#!/usr/bin/env bash
# Bring up an Xray VLESS+Reality listener on this host.
# Defaults: dest www.apple.com, port 443. Override via env:
#   DEST=dl.google.com PORT=443 ./setup.sh
set -euo pipefail

DEST="${DEST:-www.apple.com}"
PORT="${PORT:-443}"
TAG="${TAG:-fieldbox}"
XRAY_CONFIG="/usr/local/etc/xray/config.json"
CREDS_DIR="/root/.xray"
CREDS_FILE="${CREDS_DIR}/credentials"

[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 1; }

# Verify the dest actually supports what Reality needs (TLS 1.3 + X25519 + HTTP/2).
echo ">> probing dest ${DEST}:443"
probe="$(echo | openssl s_client -connect "${DEST}:443" -servername "${DEST}" \
            -tls1_3 -groups X25519 -alpn h2 2>/dev/null || true)"
echo "$probe" | grep -q "Protocol  *: TLSv1.3" \
  || { echo "dest does not negotiate TLS 1.3"; exit 1; }
echo "$probe" | grep -q "ALPN protocol: h2" \
  || { echo "dest does not negotiate HTTP/2 (ALPN h2)"; exit 1; }
echo "   ok: TLS 1.3 + X25519 + h2"

# Make sure the port we're claiming is free.
if ss -tlnH "sport = :${PORT}" | grep -q .; then
  echo "port ${PORT} is in use:"
  ss -tlnp "sport = :${PORT}"
  echo "stop the existing listener or set PORT=<other>"
  exit 1
fi

# Install xray (idempotent: re-running just upgrades).
if ! command -v xray >/dev/null; then
  echo ">> installing xray"
  bash -c "$(curl -fsSL https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
fi

# Generate identity material on-host so the private key never leaves the box.
echo ">> generating keys"
keypair="$(xray x25519)"
PRIV="$(printf '%s\n' "$keypair" | awk -F': ' '/Private/ {print $2}')"
PUB="$(printf '%s\n' "$keypair" | awk -F': ' '/Public/  {print $2}')"
UUID="$(xray uuid)"
SHORT_ID="$(openssl rand -hex 8)"

# Write the server config.
install -d -m 700 /usr/local/etc/xray
cat >"$XRAY_CONFIG" <<JSON
{
  "log": {"loglevel": "warning"},
  "inbounds": [{
    "port": ${PORT},
    "protocol": "vless",
    "settings": {
      "clients": [{
        "id": "${UUID}",
        "flow": "xtls-rprx-vision"
      }],
      "decryption": "none"
    },
    "streamSettings": {
      "network": "tcp",
      "security": "reality",
      "realitySettings": {
        "show": false,
        "dest": "${DEST}:443",
        "xver": 0,
        "serverNames": ["${DEST}"],
        "privateKey": "${PRIV}",
        "shortIds": ["${SHORT_ID}"]
      }
    },
    "sniffing": {"enabled": true, "destOverride": ["http", "tls"]}
  }],
  "outbounds": [{"protocol": "freedom"}]
}
JSON
chmod 600 "$XRAY_CONFIG"

# (Re)start.
systemctl enable --now xray >/dev/null
systemctl restart xray
sleep 1
if ! systemctl is-active --quiet xray; then
  journalctl -u xray -n 40 --no-pager
  exit 1
fi

# Stash credentials for later reuse / regeneration of the client URL.
SERVER_IP="$(curl -fsS --max-time 5 https://ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')"
install -d -m 700 "$CREDS_DIR"
cat >"$CREDS_FILE" <<EOF
SERVER_IP=${SERVER_IP}
PORT=${PORT}
DEST=${DEST}
UUID=${UUID}
PUBLIC_KEY=${PUB}
PRIVATE_KEY=${PRIV}
SHORT_ID=${SHORT_ID}
EOF
chmod 600 "$CREDS_FILE"

# Camouflage check: a TLS handshake to our port should fall through to the dest.
echo ">> verifying Reality camouflage (handshake should look like ${DEST})"
if curl -sS --max-time 10 --resolve "${DEST}:${PORT}:127.0.0.1" \
        "https://${DEST}/" -o /dev/null \
        -w "   got HTTP %{http_code} (size %{size_download} B) via 127.0.0.1:${PORT}\n"; then
  :
else
  echo "   warn: camouflage probe failed - check 'journalctl -u xray'"
fi

URL="vless://${UUID}@${SERVER_IP}:${PORT}?encryption=none&security=reality&sni=${DEST}&fp=chrome&pbk=${PUB}&sid=${SHORT_ID}&type=tcp&flow=xtls-rprx-vision#${TAG}"

cat <<EOF

=== Reality is up ===
  endpoint:   ${SERVER_IP}:${PORT}
  dest (SNI): ${DEST}
  uuid:       ${UUID}
  pubkey:     ${PUB}
  short id:   ${SHORT_ID}

Client import URL (NekoBox / Streisand / v2rayN):
${URL}

Credentials stashed at ${CREDS_FILE} (chmod 600).
EOF
