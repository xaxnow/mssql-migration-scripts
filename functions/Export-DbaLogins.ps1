# hashTable object permissions values
$objectPermissions = @{
    ApplicationRole      = "APPLICATION ROLE"
    SqlAssembly          = "ASSEMBLY"
    AsymmetricKey        = "ASYMMETRIC KEY"
    AvailabilityGroup    = "AVAILABILITY GROUP"
    Certificate          = "CERTIFICATE"
    ServiceContract      = "CONTRACT"
    Database             = "DATABASE"
    DatabaseRole         = "ROLE"
    Endpoint             = "ENDPOINT"
    ExternalDataSource   = "ExternalDataSource"
    ExternalFileFormat   = "ExternalFileFormat"
    FullTextCatalog      = "FULLTEXT CATALOG"
    FullTextStopList     = "FULLTEXT STOPLIST"
    Login                = "LOGIN"
    MessageType          = "MESSAGE TYPE"
    # ObjectOrColumn       = ""
    RemoteServiceBinding = "REMOTE SERVICE BINDING"
    Schema               = "SCHEMA"
    SearchPropertyList   = "SEARCH PROPERTY LIST"
    SecurityExpression   = "Security expression"
    Server               = "SERVER"
    ServerPrincipal      = "Login"
    ServerRole           = "SERVER ROLE"
    Service              = "SERVICE"
    SymmetricKey         = "SYMMETRIC KEY"
    User                 = "User"
    UserDefinedType      = "USER DEFINED TYPE"
    # XmlNamespace         = "XML NAMESPACE"
    
}

# convert byte[] sid to string
function Convert-SQLHexToString {
    param([byte[]]$binhash)

    $outstring = "0x"
    $binhash | ForEach-Object { $outstring += ("{0:X}" -f $_).PadLeft(2, "0") }

    return $outstring
}
#Mapping Login
function Get-LoginMapping {
    param (
        [Microsoft.SqlServer.Management.Smo.Server]$srv,
        [string]$dbName,
        [string]$login
    )
    $LoginMapping = $srv.Databases[$dbName].EnumloginMappings() | Where-Object -Property LoginName -eq $login
    return $LoginMapping.UserName
}
function Export-DbaLogins {
    param(
        [Microsoft.SqlServer.Management.Smo.Server]$server,
        [array]$dblist = @(),
        [string]$path
    )
    $logins = $server.logins | Sort-Object -Property LoginType, Name
    foreach ($l in $logins) {

        $sid = Convert-SQLHexToString $l.sid
        $sql = "SELECT convert(varbinary(256),password_hash) as hashedpass FROM sys.sql_logins Where name='" + $l.Name + "'"

        $checkPolicy = switch ($l.PasswordPolicyEnforced) {
            "TRUE" { "ON" }
            "FALSE" { "OFF" }
        }
        $checkExpiration = switch ($l.PasswordExpirationEnabled) {
            "TRUE" { "ON" }
            "FALSE" { "OFF" }
        }
        $databases = $srv.Databases
        if ($dblist.Count -eq 0) {
            $dblist = @("master", "msdb")
        }
        $newline = "`r`n"
        $outsql = ""
        if ($l.loginType -eq "SqlLogin" ) {      
            $HashedPassword = $srv.ConnectionContext.ExecuteWithResults($sql).tables.hashedpass
            $HashedPassword = Convert-SQLHexToString $HashedPassword
            ## Info : Create Login
            $SQLLoginScript = "IF NOT EXISTS (SELECT loginname FROM master.dbo.syslogins WHERE name = N'" + $l.Name + "') `r`n CREATE LOGIN [" + $l.Name + "] WITH PASSWORD = " + $HashedPassword + " HASHED,SID=" + $sid + ",DEFAULT_DATABASE=[" + $l.DefaultDatabase + "] , CHECK_POLICY = " + $checkPolicy + ", CHECK_EXPIRATION = " + $checkExpiration + ", DEFAULT_LANGUAGE = [" + $l.Language + "]" 
            $WINLoginScript = "IF NOT EXISTS (SELECT loginname FROM master.dbo.syslogins WHERE name = N'" + $l.Name + "') `r`n CREATE LOGIN [" + $l.Name + "] FROM WINDOWS WITH DEFAULT_DATABASE = [MASTER]" + ",DEFAULT_LANGUAGE = [" + $l.Language + "]"
            $members = $l.listMembers()
            $saLogin = Convert-SQLHexToString $l.sid
            if ($saLogin -eq "0x01" -or $l.name -like "##MS_*" -or $l.Name -like "NT *") {
                if ($saLogin -eq "0x01") {
                    $outsql += "/**** Skipped login.  Name: [sa], Type: " + $l.loginType + " ****/"
                } else {
                    $outsql += $newline + "/**** Skipped login.  Name: [" + $l.Name + "], Type: " + $l.loginType + " ****/"
                }
                
            } else {
                $outsql += $newline + "/**** Login: [" + $l.Name + "] ****/"
                $outsql += $newline + "USE [MASTER]"
                $outsql += $newline + "GO"
                if ($l.LoginType -eq "SqlLogin") {
                    $outsql += $newline + $SQLLoginScript
                } else {
                    $outsql += $newline + $WINLoginScript
                }
                $outsql += $newline + "GO"
                foreach ($m in $members) {
                    $alterRoleScript = "ALTER SERVER ROLE [" + $m + "] ADD MEMBER [" + $l.Name + "]"    
                    $outsql += $newline + $alterRoleScript
                    $outsql += $newline + "GO"
                }
                if ($l.DenyWindowsLogin -eq $true) {
                    $outsql += $newline + "DENY CONNECT SQL TO [" + $l.Name + "]"
                    $outsql += $newline + "GO"
                }
                if ($l.HasAccess -eq $false) {
                    $outsql += $newline + "REVOKE CONNECT SQL TO [" + $l.Name + "]"
                    $outsql += $newline + "GO"
                }
                if ($l.isdisabled -eq $true) {
                    $outsql += $newline + "ALTER LOGIN [" + $l.Name + "] DISABLE"
                    $outsql += $newline + "GO"
                }
                # Login Securables
                $securables = $srv.EnumServerPermissions() | Where-Object -Property Grantee -eq $loginName
                foreach ($securable in $securables) {
                    if ($securable.PermissionState -eq "Grant") {
                        $outsql += $newline + "GRANT " + $securable.PermissionType + " TO [" + $securable.Grantee + "]"
                    } elseif ($securable.PermissionState -eq "GrantWithGrant") {
                        $outsql += $newline + "GRANT " + $securable.PermissionType + " TO [" + $securable.Grantee + "] WITH GRANT OPTION"
                    } elseif ($securable.PermissionState -eq "Deny") {
                        $outsql += $newline + "DENY " + $securable.PermissionType + " TO [" + $securable.Grantee + "]"
                    }
                    $outsql += $newline + "GO"
                }
                $outsql += $newline + ""
                foreach ($db in $databases) {
                    if ($db.Status -eq "Normal" -and $db.Name -in $dblist) {
                        $dbName = $db.Name
                        $userName = Get-LoginMapping -srv $srv -dbName $dbName -login $l.Name
                        if ($userName.Count -gt 0) {
                            $db = $srv.Databases[$dbName]
                            $outsql += $newline + "/****  User : [" + $userName + "]  ****/"
                            $outsql += $newline + "USE [" + $dbName + "]"
                            $outsql += $newline + "GO"
                            # DB User & roles
                            $users = $db.users | Where-Object -Property Name -eq $userName
                            foreach ($user in $users) {
                                $outsql += $newline + "IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'" + $user.NAME + "') `r`n" +
                                "CREATE USER [" + $user.Name + "] FOR LOGIN [" + $l.Name + "] WITH DEFAULT_SCHEMA=[" + $user.defaultSchema + "]"
                                $roles = $user.EnumRoles()
                                if ($roles.Count -gt 0) {
                                    foreach ($role in $roles) {
                                        $outsql += $newline + "GO"
                                        $outsql += $newline + "ALTER ROLE [" + $role + "] ADD MEMBER [" + $user.name + "]"
                                        $outsql += $newline + "GO"
                                    }
                                }
                            }
                            # DB Securables
                            $securables = $db.EnumDatabasePermissions() | Where-Object -Property Grantee -eq $UserName
                            foreach ($securable in $securables) {
                                if ($securable.PermissionState -eq "Grant") {
                                    $outsql += $newline + "GRANT " + $securable.PermissionType + " TO [" + $securable.Grantee + "]"
                                } elseif ($securable.PermissionState -eq "GrantWithGrant") {
                                    $outsql += $newline + "GRANT " + $securable.PermissionType + " TO [" + $securable.Grantee + "] WITH GRANT OPTION"
                                } elseif ($securable.PermissionState -eq "Deny") {
                                    $outsql += $newline + "DENY " + $securable.PermissionType + " TO [" + $securable.Grantee + "]"
                                }
                                $outsql += $newline + "GO"

                            }
                            $outsql += $newline + ""
                            # object Permissions
                            $securables = $db.EnumObjectPermissions() | Where-Object -Property Grantee -eq $UserName
                            foreach ($securable in $securables) {
                                if ($securable.GranteeType -ne "DatabaseRole") {
                                    if ($securable.ObjectClass -eq "ObjectOrColumn") {
                                        if ($securable.PermissionState -eq "Grant") {
                                            $outsql += $newline + "GRANT " + $securable.PermissionType + " ON [" + $securable.ObjectSchema + "].[" + $securable.ObjectName + "] TO [" + $securable.Grantee + "]"
                                        } elseif ($securable.PermissionState -eq "GrantWithGrant") {
                                            $outsql += $newline + "GRANT " + $securable.PermissionType + " ON [" + $securable.ObjectSchema + "].[" + $securable.ObjectName + "] TO [" + $securable.Grantee + "] WITH GRANT OPTION"
                                        } elseif ($securable.PermissionState -eq "Deny") {
                                            $outsql += $newline + "DENY " + $securable.PermissionType + " ON [" + $securable.ObjectSchema + "].[" + $securable.ObjectName + "] TO [" + $securable.Grantee + "]"
                                        }
                                        $outsql += $newline + "GO"
                        
                                    } else {
                                        if ($objectPermissions[$securable.ObjectClass]) {
                                            if ($securable.PermissionState -eq "Grant") {
                                                $outsql += $newline + "GRANT " + $securable.PermissionType + " ON " + $objectPermissions[$securable.ObjectClass] + "::[" + $securable.ObjectName + "] TO [" + $securable.Grantee + "]"
                                            } elseif ($securable.PermissionState -eq "GrantWithGrant") {
                                                $outsql += $newline + "GRANT " + $securable.PermissionType + " ON " + $objectPermissions[$securable.ObjectClass] + "::[" + $securable.ObjectName + "] TO [" + $securable.Grantee + "] WITH GRANT OPTION"
                                            } elseif ($securable.PermissionState -eq "Deny") {
                                                $outsql += $newline + "DENY " + $securable.PermissionType + " ON " + $objectPermissions[$securable.ObjectClass] + "::[" + $securable.ObjectName + "] TO [" + $securable.Grantee + "]"
                                            }
                                            $outsql += $newline + "GO"
                                        }                        
                                    }
                                }
                            }

                        }
                        
                    }
                }
            }
            $outsql | Out-File -FilePath $path -Append 
        }
    }
}