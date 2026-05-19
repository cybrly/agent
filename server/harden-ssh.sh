#!/usr/bin/env bash
# Lock down sshd on this VPS: publickey-only, root never accepts passwords,
# sane auth timeouts. Optional fail2ban, optional port move.
#
# SAFETY: refuses to run unless an sk-ssh-ed25519 / sk-ecdsa (FIDO2/YubiKey)
# pubkey is already in /root/.ssh/authorized_keys. Override with FORCE=1 if
# you're using a plain ed25519 key on encrypted disk instead.
#
# Usage:
#   ./harden-ssh.sh                   # apply the lockdown after the prompt
#   YES=1 ./harden-ssh.sh             # skip the interactive confirmation
#   FORCE=1 ./harden-ssh.sh           # allow non-FIDO2 keys
#   PORT=49222 ./harden-ssh.sh        # also move sshd to this port (opens at iptables)
#   FAIL2BAN=1 ./harden-ssh.sh        # install + enable fail2ban
#
# Reload-not-restart is used so existing sessions don't get kicked. Always
# verify key login works in a NEW terminal before closing your current one.
set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "run as root"; exit 1; }

PORT="${PORT:-}"
FAIL2BAN="${FAIL2BAN:-0}"
FORCE="${FORCE:-0}"
YES="${YES:-}"
DROPIN="/etc/ssh/sshd_config.d/99-hardening.conf"
AK="/root/.ssh/authorized_keys"

if [ ! -s "$AK" ]; then
    echo "no $AK (or it is empty); refusing to disable password auth"; exit 1
fi

if [ "$FORCE" != "1" ] && ! grep -qE '^(sk-ssh-ed25519|sk-ecdsa)' "$AK"; then
    echo "no FIDO2 (sk-*) pubkey in $AK"
    echo "add it first, or run with FORCE=1 if you intentionally want a non-FIDO key"
    exit 1
fi

cat <<EOF

About to apply the following to ${DROPIN}:

  PasswordAuthentication        no
  KbdInteractiveAuthentication  no
  ChallengeResponseAuthentication no
  PermitRootLogin               prohibit-password
  PubkeyAuthentication          yes
  AuthenticationMethods         publickey
  MaxAuthTries                  3
  LoginGraceTime                20
  ClientAliveInterval           60
  ClientAliveCountMax           3
$( [ -n "$PORT" ] && echo "  Port                          ${PORT}" )

VERIFY FIRST in a separate terminal:
  ssh -o PreferredAuthentications=publickey root@\$(hostname -I | awk '{print \$1}')

If you cannot key-login right now, abort and fix it first.

EOF

if [ -z "$YES" ]; then
    read -r -p "Type 'i tested it' to continue: " ans
    [ "$ans" = "i tested it" ] || { echo "abort"; exit 1; }
fi

install -d -m 755 /etc/ssh/sshd_config.d
cat >"$DROPIN" <<EOF
# Managed by server/harden-ssh.sh
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
PermitRootLogin prohibit-password
PubkeyAuthentication yes
AuthenticationMethods publickey
MaxAuthTries 3
LoginGraceTime 20
ClientAliveInterval 60
ClientAliveCountMax 3
EOF

if [ -n "$PORT" ]; then
    echo "Port ${PORT}" >>"$DROPIN"
    iptables -C INPUT -p tcp --dport "${PORT}" -j ACCEPT 2>/dev/null \
        || iptables -A INPUT -p tcp --dport "${PORT}" -j ACCEPT
    iptables-save > /etc/iptables/rules.v4
fi

if ! sshd -t; then
    echo "sshd config rejected by 'sshd -t'; not reloading"; exit 1
fi
systemctl reload ssh

if [ "$FAIL2BAN" = "1" ]; then
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq fail2ban
    systemctl enable --now fail2ban
fi

cat <<EOF

=== sshd hardened ===
  drop-in:   ${DROPIN}
$( [ -n "$PORT" ] && echo "  port:      ${PORT} (iptables opened, persisted)" )
$( [ "$FAIL2BAN" = "1" ] && echo "  fail2ban:  enabled" )

Verify NOW from a NEW terminal before closing your existing session:

  ssh root@<this-host>${PORT:+ -p ${PORT}}
  ssh -o PreferredAuthentications=password root@<this-host>${PORT:+ -p ${PORT}}   # MUST be denied

If something is wrong, your current session is still open — fix it from there.
EOF
