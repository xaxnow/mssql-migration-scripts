# migration-mssql
migration sql server databases

## items

some items still need you type password , such as credentials

1. logins
2. server roles
3. jobs
4. linked servers
5. credentials
6. mails
7. master db objects. e.g. table,sp,schema

## usage

default user is "sql_user" .
default password gets from the "SecurityPwd.txt" if you do not specified user & password in "instanceInfo.txt"
**instanceInfo.txt format**:
```
# if user & password is "",default user & password will be used
ip,port,user,password
```
**run**:
```
powershell -ExecutionPolicy ByPass .\Start-Run.ps1
```

## what you need to know if you want to write some such scripts

**SMO** : SQL Server Management Object

## reference

[https://dbatools.io](https://dbatools.io/)
