---
title: SMB (139/445)
category: enumeration
description: Enumerate shares, users, sessions and known vulns on SMB.
tags: [smb, windows, shares]
os: [any]
ports: [139, 445]
order: 10
---

## Quick fingerprint

```bash
nmap -p139,445 -sCV --script "smb-os-discovery,smb-protocols,smb-security-mode,smb2-security-mode,smb-enum-shares" {{RHOST}}
```

## Anonymous / null session enum

```bash
smbclient -L //{{RHOST}}/ -N
smbmap -H {{RHOST}} -u '' -p ''
enum4linux-ng -A {{RHOST}}
rpcclient -U "" -N {{RHOST}}
```

Inside `rpcclient`:

```text
enumdomusers
enumdomgroups
queryuser 0x3e8
querygroupmem 0x201
lsaenumsid
getdompwinfo
```

## Authenticated enum

```bash
smbclient -L //{{RHOST}}/ -U "{{USER}}%password"
smbmap -H {{RHOST}} -u "{{USER}}" -p "password" -R
crackmapexec smb {{RHOST}} -u "{{USER}}" -p "password" --shares --users --groups --pass-pol --loggedon-users --sessions
nxc smb {{RHOST}} -u "{{USER}}" -p "password" --shares      # netexec, CME successor
```

## Mount a share

```bash
smbclient //{{RHOST}}/Share -U "{{USER}}"
sudo mount -t cifs //{{RHOST}}/Share /mnt/s -o username={{USER}},password=pass,vers=3.0
```

## Spider for sensitive files

```bash
nxc smb {{RHOST}} -u "{{USER}}" -p "pass" -M spider_plus -o EXCLUDE_DIRS=Windows,IPC$
smbmap -H {{RHOST}} -u "{{USER}}" -p "pass" --depth 5 -R Share
```

## Common vulns to probe

```bash
nmap -p445 --script smb-vuln-ms17-010,smb-vuln-ms08-067 {{RHOST}}
nxc smb {{RHOST}} -u '' -p '' -M zerologon
nxc smb {{RHOST}} -u '' -p '' -M petitpotam
```

## Password spray (carefully — lockouts)

```bash
nxc smb {{RHOST}} -u users.txt -p 'Spring2025!' --continue-on-success
kerbrute passwordspray -d {{DOMAIN}} users.txt 'Spring2025!'
```
