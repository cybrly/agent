---
title: Passive Recon & OSINT
category: recon
description: Gather intel on a target without sending packets to it.
tags: [osint, dns, whois, subdomain]
os: [any]
order: 10
---

## WHOIS & registration

```bash
whois {{RHOST}}
whois example.com
```

## DNS records

```bash
dig example.com ANY +noall +answer
dig +short example.com
dig +short MX example.com
dig +short NS example.com
dig +short TXT example.com
host -t AXFR example.com ns1.example.com   # zone transfer (rarely allowed)
```

## Subdomain enumeration (passive)

```bash
subfinder -d example.com -all -silent
amass enum -passive -d example.com
assetfinder --subs-only example.com
curl -s "https://crt.sh/?q=%25.example.com&output=json" | jq -r '.[].name_value' | sort -u
```

## Resolve & probe

```bash
dnsx -l subs.txt -a -resp -silent
httpx -l subs.txt -title -tech-detect -status-code -silent
```

## Search engines & code

- `site:example.com -www` — find non-www subdomains
- `intitle:"index of" site:example.com`
- `filetype:pdf site:example.com confidential`
- GitHub: `org:example "BEGIN RSA PRIVATE"` · `"api_key"`
- Wayback: `curl -s "http://web.archive.org/cdx/search/cdx?url=*.example.com/*&output=text&fl=original&collapse=urlkey"`

## Mail / breach data

```bash
theHarvester -d example.com -b all
holehe user@example.com
h8mail -t user@example.com
```

## Tech fingerprinting

```bash
whatweb https://{{RHOST}}
wafw00f https://{{RHOST}}
nuclei -u https://{{RHOST}} -t technologies/
```
