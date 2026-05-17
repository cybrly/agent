---
title: HTTP / HTTPS (80, 443, 8080)
category: enumeration
description: Web server fingerprinting, content discovery, and vhost enumeration.
tags: [http, web, fuzzing]
os: [any]
ports: [80, 443, 8080, 8443]
order: 5
---

## Fingerprint

```bash
curl -sI http://{{RHOST}}/
whatweb -a3 http://{{RHOST}}/
nikto -h http://{{RHOST}}/
nuclei -u http://{{RHOST}}/ -t technologies/,exposures/,misconfiguration/
```

## Content discovery

```bash
# Directories & files
feroxbuster -u http://{{RHOST}}/ -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt -x php,html,txt,bak -t 50
ffuf -u http://{{RHOST}}/FUZZ -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt -e .php,.html,.txt -mc all -fc 404
gobuster dir -u http://{{RHOST}}/ -w /usr/share/seclists/Discovery/Web-Content/common.txt -x php,txt
```

## VHost / subdomain fuzzing

```bash
# vhost
ffuf -u http://{{RHOST}}/ -H "Host: FUZZ.example.com" -w subs.txt -fs <size-of-default>

# Subdomains (DNS)
ffuf -u http://FUZZ.example.com/ -w subs.txt -mc all -fc 404
gobuster vhost -u http://{{RHOST}} -w subs.txt --append-domain
```

## Parameter fuzzing

```bash
ffuf -u "http://{{RHOST}}/page.php?FUZZ=test" -w params.txt -fs <baseline>
arjun -u "http://{{RHOST}}/page.php" --stable
x8 -u "http://{{RHOST}}/api" -w params.txt
```

## Methods, headers, CORS

```bash
curl -sI -X OPTIONS http://{{RHOST}}/ -H "Origin: https://evil.com"
nmap --script http-methods --script-args http-methods.url-path=/ -p80 {{RHOST}}
```

## Common low-hanging files

```text
/robots.txt    /sitemap.xml    /.git/HEAD    /.env    /.DS_Store
/.svn/entries  /backup.zip     /server-status /actuator/health
/api/swagger.json /openapi.json /phpinfo.php   /wp-login.php
```

## SSL / TLS

```bash
sslscan {{RHOST}}:443
testssl.sh {{RHOST}}
openssl s_client -connect {{RHOST}}:443 -servername example.com </dev/null
```
