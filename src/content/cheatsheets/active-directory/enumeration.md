---
title: AD Enumeration
category: active-directory
description: Map users, groups, ACLs, sessions from Linux or Windows.
tags: [ad, ldap, bloodhound, enumeration]
os: [any]
order: 10
---

## From Linux

```bash
# Unauthenticated checks
nxc smb {{RHOST}} -u '' -p ''                                  # null session?
ldapsearch -x -H ldap://{{RHOST}} -s base namingcontexts        # naming contexts
enum4linux-ng -A {{RHOST}}

# Authenticated
nxc smb {{RHOST}} -u "{{USER}}" -p "pass" --users --groups --pass-pol
nxc ldap {{RHOST}} -u "{{USER}}" -p "pass" --users --groups --trusted-for-delegation --asreproast asrep.txt --kerberoasting kerb.txt

# ldapsearch tree
ldapsearch -x -H ldap://{{RHOST}} -D "{{USER}}@{{DOMAIN}}" -w 'pass' -b "DC=corp,DC=local" "(objectClass=user)" sAMAccountName description memberOf
```

## BloodHound collection

```bash
# Linux — bloodhound-python
bloodhound-python -d {{DOMAIN}} -u "{{USER}}" -p 'pass' -ns {{RHOST}} -c All --zip

# Linux — netexec
nxc ldap {{RHOST}} -u "{{USER}}" -p 'pass' --bloodhound -c All --dns-server {{RHOST}}

# Windows
SharpHound.exe -c All --zipfilename loot.zip
```

## Windows-side enum (PowerView / native)

```powershell
Get-NetUser -SPN | select samaccountname,serviceprincipalname
Get-NetUser -PreauthNotRequired
Get-NetGroupMember "Domain Admins"
Get-NetComputer -Unconstrained
Get-NetComputer -TrustedToAuth
Find-LocalAdminAccess
Find-DomainShare -CheckShareAccess
Get-NetGPO | select displayname,gpcfilesyspath
Get-DomainObjectAcl -Identity "DOMAIN ADMINS" -ResolveGUIDs | ? {$_.ActiveDirectoryRights -match "GenericAll|WriteDacl|WriteOwner|AllExtendedRights"}
```

Native:

```cmd
net user /domain
net group "Domain Admins" /domain
net localgroup administrators
nltest /domain_trusts /all_trusts
setspn -T {{DOMAIN}} -Q */*
```

## Username discovery without creds

```bash
# Validate users via Kerberos (no lockout)
kerbrute userenum -d {{DOMAIN}} --dc {{RHOST}} users.txt
```

## Sessions & shares

```bash
nxc smb {{RHOST}} -u "{{USER}}" -p 'pass' --loggedon-users --sessions --shares
```
