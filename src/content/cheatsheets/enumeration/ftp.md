---
title: FTP (21)
category: enumeration
description: Banner, anon access, version checks.
tags: [ftp]
os: [any]
ports: [21]
order: 30
---

## Banner & scripts

```bash
nmap -p21 -sCV --script "ftp-anon,ftp-syst,ftp-vsftpd-backdoor,ftp-proftpd-backdoor" {{RHOST}}
nc -nv {{RHOST}} 21
```

## Anonymous login

```bash
ftp -nv {{RHOST}}
# user anonymous
# pass anonymous@
ls -la
binary
mget *
```

Or via `curl`:

```bash
curl -u 'anonymous:anonymous@' ftp://{{RHOST}}/ -s -l
curl -u 'anonymous:' ftp://{{RHOST}}/file -o file
```

## Bruteforce (auth)

```bash
hydra -L users.txt -P pass.txt ftp://{{RHOST}} -t 4 -f
medusa -h {{RHOST}} -U users.txt -P pass.txt -M ftp
```

## Notable

- vsftpd 2.3.4 backdoor (`:)` smiley user → port 6200 shell)
- ProFTPD 1.3.5 mod_copy (`SITE CPFR/CPTO`)
- File upload may land in webroot — chain with HTTP RCE
