# migration-mssql
migration sql server databases

## items

some items still need you type password , such as credentials.
database roles just include master & msdb database.

1. logins
2. server roles
3. database roles
4. jobs
5. linked servers
6. credentials
7. mails
8. master db objects. e.g. table,sp,schema

## requirement

- SMO. If you installed SSMS you do not need to install it .
- SQL Server version : successfully run in above 2014

## usage

default user is "sql_user" .
default password gets from the "SecurityPwd.txt" if you do not specified user & password in "instanceInfo.txt"

**instanceInfo.txt format**:
```
# if user & password is "",default user & password will be used
ip,port,user,password
```
**run script**:
```
powershell -ExecutionPolicy ByPass .\Start-Run.ps1
```

## what you need to know if you want to write some such scripts

**SMO** : SQL Server Management Object

## reference

[https://dbatools.io](https://dbatools.io/)
