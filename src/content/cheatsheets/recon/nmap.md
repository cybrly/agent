---
title: Nmap — Port & Service Scanning
category: recon
description: From quick sweep to deep service enumeration.
tags: [nmap, ports, scanning]
os: [any]
order: 5
---

## Speed sweeps

```bash
# Fast all-ports TCP — find what's open, then scan deeper
nmap -p- --min-rate 5000 -T4 -Pn {{RHOST}} -oN tcp-fast.txt

# Top 1000 with version detection
nmap -sCV -T4 {{RHOST}} -oN tcp-top.txt
```

## Deep scan of discovered ports

```bash
ports=$(grep -oP '\d+/open' tcp-fast.txt | cut -d/ -f1 | paste -sd,)
nmap -p$ports -sCV -A -T4 {{RHOST}} -oN tcp-deep.txt
```

## UDP top ports (slow — pick targets)

```bash
sudo nmap -sU --top-ports 50 --min-rate 2000 -T4 {{RHOST}} -oN udp.txt
```

## Common useful flags

- `-Pn` skip ping (treat as alive)
- `-sS` SYN (default as root) · `-sT` full connect (no root)
- `-sC` default scripts · `-sV` version · `-A` aggressive (`-sC -sV -O --traceroute`)
- `-oA name` save in all formats · `-iL hosts.txt` from file
- `--script vuln,safe` · `--script-args ...`
- `--reason` show why a port is marked open

## Useful NSE scripts

```bash
nmap --script smb-vuln* -p139,445 {{RHOST}}
nmap --script http-enum,http-title,http-methods -p80,443 {{RHOST}}
nmap --script ssl-enum-ciphers -p443 {{RHOST}}
nmap --script ssh2-enum-algos,ssh-hostkey -p22 {{RHOST}}
nmap --script dns-brute --script-args dns-brute.domain=example.com
```

## Stealth & evasion (lab use)

```bash
nmap -sS -f --mtu 16 -D RND:5 --data-length 50 -T2 {{RHOST}}
nmap --source-port 53 -Pn {{RHOST}}
```

## Quick targeted alternatives

```bash
rustscan -a {{RHOST}} --ulimit 5000 -- -sCV     # rustscan → nmap pipe
masscan -p1-65535 {{RHOST}} --rate=10000 -e tun0
naabu -host {{RHOST}} -p- -rate 5000
```
