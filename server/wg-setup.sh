#!/usr/bin/env bash
# Bring up a WireGuard server (UDP/443) + an in-tunnel Unbound resolver
# (DNS-over-TLS upstream) on this VPS. Idempotent.
#
# Coexists with the Reality TCP/443 listener from server/setup.sh: WG is UDP,
# Reality is TCP, same port number is fine because they're different protocols.
set -euo pipefail

WG_PORT="${WG_PORT:-443}"
WG_NET="${WG_NET:-10.66.0.0/24}"
WG_SERVER_IP="${WG_SERVER_IP:-10.66.0.1}"
WAN_IF="${WAN_IF:-$(ip -o route get 1.1.1.1 | awk '{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}')}"

[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 1; }
[ -n "${WAN_IF}" ]   || { echo "could not detect WAN interface; set WAN_IF="; exit 1; }

echo ">> installing wireguard + unbound"
echo "iptables-persistent iptables-persistent/autosave_v4 boolean true" | debconf-set-selections
echo "iptables-persistent iptables-persistent/autosave_v6 boolean true" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    wireguard-tools unbound unbound-anchor iptables-persistent curl

echo ">> generating server keypair (only if missing)"
install -d -m 700 /etc/wireguard
if [ ! -f /etc/wireguard/server.key ]; then
    umask 077
    wg genkey | tee /etc/wireguard/server.key | wg pubkey > /etc/wireguard/server.pub
fi
SERVER_PRIV="$(cat /etc/wireguard/server.key)"
SERVER_PUB="$(cat /etc/wireguard/server.pub)"

echo ">> writing /etc/wireguard/wg0.conf"
cat >/etc/wireguard/wg0.conf <<EOF
[Interface]
Address    = ${WG_SERVER_IP}/24
ListenPort = ${WG_PORT}
PrivateKey = ${SERVER_PRIV}
PostUp     = iptables -t nat -A POSTROUTING -s ${WG_NET} -o ${WAN_IF} -j MASQUERADE; iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT
PostDown   = iptables -t nat -D POSTROUTING -s ${WG_NET} -o ${WAN_IF} -j MASQUERADE; iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT

# Peers are appended live by /usr/local/bin/wg-add-peer
EOF
chmod 600 /etc/wireguard/wg0.conf

echo ">> enabling ip_forward"
cat >/etc/sysctl.d/99-wireguard.conf <<EOF
net.ipv4.ip_forward=1
net.ipv4.conf.all.send_redirects=0
EOF
sysctl --system >/dev/null

echo ">> configuring unbound (DoT upstream to Quad9 + Cloudflare)"
install -d -m 755 /etc/unbound/unbound.conf.d
cat >/etc/unbound/unbound.conf.d/wg-resolver.conf <<EOF
server:
    verbosity: 0
    interface: ${WG_SERVER_IP}
    interface: 127.0.0.1
    port: 53
    do-ip6: no
    do-tcp: yes
    do-udp: yes
    access-control: 0.0.0.0/0 refuse
    access-control: 127.0.0.0/8 allow
    access-control: ${WG_NET} allow
    hide-identity: yes
    hide-version: yes
    qname-minimisation: yes
    aggressive-nsec: yes
    prefetch: yes
    use-caps-for-id: no
    harden-glue: yes
    harden-dnssec-stripped: yes
    rrset-roundrobin: yes

forward-zone:
    name: "."
    forward-tls-upstream: yes
    forward-addr: 9.9.9.9@853#dns.quad9.net
    forward-addr: 149.112.112.112@853#dns.quad9.net
    forward-addr: 1.1.1.1@853#cloudflare-dns.com
    forward-addr: 1.0.0.1@853#cloudflare-dns.com
EOF

# Stop systemd-resolved if it's hogging :53 on the WG IP; we use it on 127.0.0.53 anyway.
if systemctl is-active --quiet systemd-resolved; then
    mkdir -p /etc/systemd/resolved.conf.d
    cat >/etc/systemd/resolved.conf.d/wg-resolver.conf <<'EOF'
[Resolve]
DNSStubListener=no
EOF
    systemctl restart systemd-resolved
fi

systemctl enable --now unbound >/dev/null
systemctl restart unbound

echo ">> opening UDP/${WG_PORT} at netfilter"
iptables -C INPUT -p udp --dport "${WG_PORT}" -j ACCEPT 2>/dev/null \
    || iptables -A INPUT -p udp --dport "${WG_PORT}" -j ACCEPT
iptables-save > /etc/iptables/rules.v4

echo ">> installing /usr/local/bin/wg-add-peer"
cat >/usr/local/bin/wg-add-peer <<'AEOF'
#!/usr/bin/env bash
# Usage: wg-add-peer <name> <pubkey> [tunnel-ip-last-octet]
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 1; }
NAME="${1:?name (free-form label)}"
PUB="${2:?pubkey}"
SUFFIX="${3:-}"
WG_NET_PREFIX="10.66.0"

if grep -qF "PublicKey  = ${PUB}" /etc/wireguard/wg0.conf 2>/dev/null \
   || grep -qF "PublicKey = ${PUB}"  /etc/wireguard/wg0.conf 2>/dev/null; then
    echo "peer already present"; exit 0
fi

if [ -z "$SUFFIX" ]; then
    used="$(grep -oE "${WG_NET_PREFIX}\.[0-9]+" /etc/wireguard/wg0.conf | awk -F. '{print $4}' | sort -un)"
    SUFFIX=2
    while echo "$used" | grep -q "^${SUFFIX}$"; do SUFFIX=$((SUFFIX+1)); done
fi
TUN_IP="${WG_NET_PREFIX}.${SUFFIX}"

cat >>/etc/wireguard/wg0.conf <<EOF

# ${NAME}
[Peer]
PublicKey  = ${PUB}
AllowedIPs = ${TUN_IP}/32
EOF

wg set wg0 peer "${PUB}" allowed-ips "${TUN_IP}/32"
echo "added peer '${NAME}' (${PUB}) -> ${TUN_IP}"
AEOF
chmod +x /usr/local/bin/wg-add-peer

echo ">> starting wg0"
systemctl enable wg-quick@wg0 >/dev/null
systemctl restart wg-quick@wg0
sleep 1
systemctl is-active --quiet wg-quick@wg0 \
    || { journalctl -u wg-quick@wg0 -n 40 --no-pager; exit 1; }

PUB_IP="$(curl -fsS --max-time 5 https://ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')"

cat <<EOF

=== WireGuard server is up ===
  endpoint:        ${PUB_IP}:${WG_PORT}/udp
  network:         ${WG_NET}
  server tunnel:   ${WG_SERVER_IP}  (also the in-tunnel DNS resolver)
  server pubkey:   ${SERVER_PUB}

Next steps:

  1. SSH into the Slate 7 (LAN side):

       ssh root@192.168.8.1

  2. Paste/run router/slate7-setup.sh with:

       SERVER_PUB='${SERVER_PUB}' \\
       SERVER_ENDPOINT='${PUB_IP}:${WG_PORT}' \\
       sh slate7-setup.sh

  3. It will print the router's public key. Back here, run:

       wg-add-peer slate7 <ROUTER-PUBKEY>

  4. On the router or a client behind it:

       wg show wgclient                 # expect a recent handshake
       curl ifconfig.me                 # expect ${PUB_IP}
       dig +short whoami.cloudflare CH TXT @${WG_SERVER_IP}
EOF
