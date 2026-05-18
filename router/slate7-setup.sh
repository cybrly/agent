#!/bin/sh
# Configure a GL.iNet Slate 7 (or any OpenWrt 23+ router) as a WireGuard
# client that tunnels ALL LAN traffic through the VPS, with kill switch,
# DNS forced through the in-tunnel resolver, and IPv6 disabled.
#
# Required env:
#   SERVER_PUB        WireGuard server public key
#   SERVER_ENDPOINT   host:port, e.g. 165.245.175.93:443
# Optional env:
#   TUN_IP            this router's tunnel address          (default 10.66.0.2)
#   DNS_IP            in-tunnel DNS resolver to point at    (default 10.66.0.1)
#   WG_MTU            tunnel MTU                            (default 1420)
set -eu

: "${SERVER_PUB:?set SERVER_PUB}"
: "${SERVER_ENDPOINT:?set SERVER_ENDPOINT, e.g. 1.2.3.4:443}"
TUN_IP="${TUN_IP:-10.66.0.2}"
DNS_IP="${DNS_IP:-10.66.0.1}"
WG_MTU="${WG_MTU:-1420}"
EP_HOST="${SERVER_ENDPOINT%:*}"
EP_PORT="${SERVER_ENDPOINT##*:}"

[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 1; }
command -v uci >/dev/null || { echo "this script is for OpenWrt / GL.iNet"; exit 1; }

if ! command -v wg >/dev/null; then
    echo ">> installing wireguard-tools"
    opkg update >/dev/null
    opkg install wireguard-tools kmod-wireguard
fi

echo ">> generating router keypair (only if missing)"
mkdir -p /etc/wireguard && chmod 700 /etc/wireguard
if [ ! -f /etc/wireguard/wgclient.key ]; then
    umask 077
    wg genkey | tee /etc/wireguard/wgclient.key | wg pubkey > /etc/wireguard/wgclient.pub
fi
CLIENT_PRIV="$(cat /etc/wireguard/wgclient.key)"
CLIENT_PUB="$(cat /etc/wireguard/wgclient.pub)"

echo ">> wiping any prior wgclient config"
uci -q delete network.wgclient || true
# Remove any orphaned wireguard_wgclient peer sections
i=0
while [ "$i" -lt 32 ]; do
    uci -q delete "network.@wireguard_wgclient[0]" || break
    i=$((i+1))
done

echo ">> writing network UCI"
uci set network.wgclient=interface
uci set network.wgclient.proto='wireguard'
uci set network.wgclient.private_key="${CLIENT_PRIV}"
uci add_list network.wgclient.addresses="${TUN_IP}/32"
uci set network.wgclient.mtu="${WG_MTU}"

PEER="$(uci add network wireguard_wgclient)"
uci set "network.${PEER}.public_key=${SERVER_PUB}"
uci set "network.${PEER}.endpoint_host=${EP_HOST}"
uci set "network.${PEER}.endpoint_port=${EP_PORT}"
uci set "network.${PEER}.persistent_keepalive=25"
uci set "network.${PEER}.route_allowed_ips=1"
uci add_list "network.${PEER}.allowed_ips=0.0.0.0/0"

echo ">> disabling IPv6 (prevents leaks around the v4-only tunnel)"
uci -q set network.wan6.disabled='1' || true
uci -q delete network.lan.ip6assign || true
uci -q delete network.lan.ipv6      || true
uci -q set dhcp.lan.dhcpv6='disabled'   || true
uci -q set dhcp.lan.ra='disabled'       || true

echo ">> firewall zone for wgclient"
# Remove any prior wgzone
i=0
while [ "$i" -lt 32 ]; do
    uci -q delete firewall.wgzone && i=$((i+1)) || break
done
uci set firewall.wgzone=zone
uci set firewall.wgzone.name='wgzone'
uci set firewall.wgzone.input='REJECT'
uci set firewall.wgzone.output='ACCEPT'
uci set firewall.wgzone.forward='REJECT'
uci set firewall.wgzone.masq='1'
uci set firewall.wgzone.mtu_fix='1'
uci add_list firewall.wgzone.network='wgclient'

echo ">> forwarding rules: lan -> wgzone only (kill switch)"
# Drop any prior lan->wan and lan->wgzone forwardings; rewrite cleanly.
for f in $(uci show firewall 2>/dev/null | awk -F'[.=]' '/=forwarding$/ {print $2}'); do
    src="$(uci -q get firewall.$f.src || true)"
    dst="$(uci -q get firewall.$f.dest || true)"
    if [ "$src" = "lan" ] && { [ "$dst" = "wan" ] || [ "$dst" = "wgzone" ]; }; then
        uci delete "firewall.$f"
    fi
done
F="$(uci add firewall forwarding)"
uci set "firewall.${F}.src=lan"
uci set "firewall.${F}.dest=wgzone"

echo ">> forcing LAN clients onto in-tunnel resolver (${DNS_IP})"
uci -q delete dhcp.@dnsmasq[0].server || true
uci add_list dhcp.@dnsmasq[0].server="${DNS_IP}"
uci set dhcp.@dnsmasq[0].noresolv='1'
uci set dhcp.@dnsmasq[0].rebind_protection='0'

echo ">> DNS hijack: redirect any LAN client trying to use a different resolver"
for r in $(uci show firewall 2>/dev/null | awk -F'[.=]' '/=redirect$/ {print $2}'); do
    name="$(uci -q get firewall.$r.name || true)"
    case "$name" in dns-hijack-*) uci delete "firewall.$r" ;; esac
done
for proto in tcp udp; do
    R="$(uci add firewall redirect)"
    uci set "firewall.${R}.name=dns-hijack-${proto}"
    uci set "firewall.${R}.src=lan"
    uci set "firewall.${R}.src_dport=53"
    uci set "firewall.${R}.proto=${proto}"
    uci set "firewall.${R}.dest_port=53"
    uci set "firewall.${R}.target=DNAT"
done

uci commit network
uci commit firewall
uci commit dhcp

echo ">> applying"
/etc/init.d/network restart
/etc/init.d/firewall restart
/etc/init.d/dnsmasq restart

sleep 3

cat <<EOF

=== Slate 7 configured ===
  router pubkey:   ${CLIENT_PUB}
  tunnel IP:       ${TUN_IP}
  in-tunnel DNS:   ${DNS_IP}
  WG endpoint:     ${SERVER_ENDPOINT}/udp
  kill switch:     ON (LAN clients have no internet until WG is up)

Next on the VPS:

  wg-add-peer slate7 ${CLIENT_PUB}

Then verify here on the router:

  wg show wgclient                     # 'latest handshake' should be seconds ago
  ip route get 1.1.1.1                 # should go via wgclient
  nslookup ifconfig.me ${DNS_IP}       # resolver test
  curl ifconfig.me                     # should print the VPS public IP

Reminder: rotate the router's root login password (passwd) and consider
disabling password auth in favour of an SSH key in /etc/dropbear/.
EOF
