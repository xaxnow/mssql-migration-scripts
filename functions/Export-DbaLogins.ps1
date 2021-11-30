function Export-DbaLogins {
    param(
        [Microsoft.SqlServer.Management.Smo.Server]$server
    )
    function Convert-SQLHexToString {
        param([parameter(Mandatory = $true)] $binhash)

        $outstring = "0x"
        $binhash | ForEach-Object { $outstring += ("{0:X}" -f $_).PadLeft(2, "0") }

        return $outstring
    }
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
        # $mustChangePassword = switch ($l.MustChangePassword) {
        #     "TRUE" { "ON" }
        #     "FALSE" { "OFF" }
        #     default { $null }
        # }
        "/*********** Login : [" + $l.Name + "] ***********/"
        #sqllogin
        if ($l.loginType -eq "SqlLogin") {      
            $HashedPassword = $srv.ConnectionContext.ExecuteWithResults($sql).tables.hashedpass
            $HashedPassword = Convert-SQLHexToString $HashedPassword
            ## Info : Create Login
            $LoginScript = "CREATE LOGIN [" + $l.Name + "] WITH PASSWORD = " + $HashedPassword + " HASHED,SID=" + $sid + ",DEFAULT_DATABASE=[" + $l.DefaultDatabase + "] , CHECK_POLICY = " + $checkPolicy + ", CHECK_EXPIRATION = " + $checkExpiration 
            
            $members = $l.listMembers()
            $saLogin = Convert-SQLHexToString $l.sid
            if ($saLogin -eq "0x01" -or $l.name -like "##MS_*") {
                "--" + $LoginScript
                if ($l.DenyWindowsLogin -eq $true) {
                    "--DENY CONNECT SQL TO [" + $l.Name + "]"
                }
                if ($l.HasAccess -eq $false) {
                    "--REVOKE CONNECT SQL TO [" + $l.Name + "]"
                }
                if ($l.isdisabled -eq $true) {
                    "--ALTER LOGIN [" + $l.Name + "] DISABLE"
                }
                "--GO"
            } else {
                $LoginScript
                foreach ($m in $members) {
                    $alterRoleScript = "ALTER SERVER ROLE [" + $m + "] ADD MEMBER [" + $l.Name + "]"    
                    $alterRoleScript
                }
                if ($l.DenyWindowsLogin -eq $true) {
                    "DENY CONNECT SQL TO [" + $l.Name + "]"
                }
                if ($l.HasAccess -eq $false) {
                    "REVOKE CONNECT SQL TO [" + $l.Name + "]"
                }
                if ($l.isdisabled -eq $true) {
                    "ALTER LOGIN [" + $l.Name + "] DISABLE"
                }
                "GO"
    
            }
            

        }
        #windows or windows group login
        elseif ($l.loginType -in ("WindowsUser", "WindowsGroup")) {
            "--CREATE LOGIN [" + $l.Name + "] FROM WINDOWS WITH DEFAULT_DATABASE = [MASTER]"
            if ($l.DenyWindowsLogin -eq $true) {
                "--DENY CONNECT SQL TO [" + $l.Name + "]"
            }
            if ($l.HasAccess -eq $false) {
                "--REVOKE CONNECT SQL TO [" + $l.Name + "]"
            }
            if ($l.isdisabled -eq $true) {
                "--ALTER LOGIN [" + $l.Name + "] DISABLE"
            }
            "--GO"
        }
        
    }
    
    "/*********** Handle Server Permissions ***********/"
    
    "USE [master]"
    "GO"
    if ($srv.EnumServerPermissions().Count -gt 0) {
        $serverPermissions = $srv.EnumServerPermissions()
        foreach ($sp in $serverPermissions) {
            if ($sp.Grantee -notlike "##MS*" -and $sp.Grantee -notlike "NT *" -and $sp.Grantee -notlike "*\*") {
                if ($sp.PermissionState -eq "Grant") {
                    "GRANT " + $sp.PermissionType + " TO [" + $sp.Grantee + "]"
                } elseif ($sp.PermissionState -eq "GrantWithGrant") {
                    "GRANT " + $sp.PermissionType + " TO [" + $sp.Grantee + "] WITH GRANT OPTION"
                } elseif ($sp.PermissionState -eq "Deny") {
                    "DENY " + $sp.PermissionType + " TO [" + $sp.Grantee + "]"
                }
            } else {
                if ($sp.PermissionState -eq "Grant") {
                    "--GRANT " + $sp.PermissionType + " TO [" + $sp.Grantee + "]"
                } elseif ($sp.PermissionState -eq "GrantWithGrant") {
                    "--GRANT " + $sp.PermissionType + " TO [" + $sp.Grantee + "] WITH GRANT OPTION"
                } elseif ($sp.PermissionState -eq "Deny") {
                    "--DENY " + $sp.PermissionType + " TO [" + $sp.Grantee + "]"
                }
            }
        }
        "GO"
    }
    
}

function Export-DbaSystemDBUser {
    param(
        [Microsoft.SqlServer.Management.Smo.SqlSmoObject]$server
    )
    $Databases = $server.Databases
    foreach ($db in $Databases) {
        # if ($db.Name -eq "model") {
        if ($db.id -lt 5) {
            "/*********** Create Databases Roles ***********/"
            "USE [" + $db.Name + "]"
            "GO"
            foreach ($role in $db.Roles) {
                if (($role.isFixedRole -eq $false) -and ($role.Name -inotin ("public", "DatabaseMailUserRole", "db_ssisadmin", "db_ssisltduser", "db_ssisoperator", "dc_admin", "dc_operator", "dc_proxy", "PolicyAdministratorRole", "ServerGroupAdministratorRole", "ServerGroupReaderRole", "SQLAgentOperatorRole", "SQLAgentUserRole", "SQLAgentReaderRole", "TargetServersRole", "UtilityCMRReader", "UtilityIMRReader", "UtilityIMRWriter","RSExecRole")) ) {
                    $role.Script()
                } else {
                    "--" + $role.Script()
                }
            }
            "GO"
            "/*********** Create Databases Schemas ***********/"
            "USE [" + $db.Name + "]"
            "GO"
            foreach ($schema in $db.Schemas) {
                if (($schema.IsSystemObject -eq $false) -and ($Schema.Name -notlike "NT *") -and ($schema.Name -inotin ("smart_admin", "managed_backup", "public", "DatabaseMailUserRole", "db_ssisadmin", "db_ssisltduser", "db_ssisoperator", "dc_admin", "dc_operator", "dc_proxy", "PolicyAdministratorRole", "ServerGroupAdministratorRole", "ServerGroupReaderRole", "SQLAgentOperatorRole", "SQLAgentUserRole", "SQLAgentReaderRole", "TargetServersRole", "UtilityCMRReader", "UtilityIMRReader", "UtilityIMRWriter","RSExecRole"))) {
                    $schema.Script()
                } else {
                    "--" + $schema.Script()
                }
            } 
            "GO"
            "/*********** Create Databases Users & Add Roles ***********/"
            foreach ($User in $db.Users) {
                if (($User.IsSystemObject -eq $false) -and ($User.Name -notlike "NT *") -and ($User.LoginType -eq "SqlLogin") -and ($User.Name -notlike "##MS*") -and ($User.Name -cne "MS_DataCollectorInternalUser") ) {
                    "/*********** Login: [" + $User.Name + "] /***********"
                    "USE " + $db.Name
                    "GO"
                    # $User.Name +":" +$User.isMember("DatabaseMailUserRole") #是哪个的成员
                    $User.Script()
                    #Schema的Owner
                    # if ($User.EnumOwnedObjects().count -ne 0) {
                    #     $schemas = $User.EnumOwnedObjects().GetNameForType("Schema")
                    #     foreach ($schema in $schemas) {
                    #         "ALTER AUTHORIZATION ON SCHEMA::[" + $schema + "] TO [" + $User.Name + "]"
                    #     }
                    # }
                    if ($User.EnumRoles().Count -ne 0) {
    
                        $roles = $User.EnumRoles()
                        foreach ($role in $roles) {
                            "ALTER ROLE [" + $role + "] ADD MEMBER [" + $User.name + "]"
                        }
                    }
                    "GO"
                }
                if ($User.LoginType -ne "SqlLogin") {
                    "/*********** Login: [" + $User.Name + "] ***********/"
                    "--USE " + $db.Name
                    "--GO"
                    # $User.Name +":" +$User.isMember("DatabaseMailUserRole") #是哪个的成员
                    "--" + $User.Script()
                    if ($User.EnumRoles().Count -ne 0) {
    
                        $roles = $User.EnumRoles()
                        foreach ($role in $roles) {
                            "--ALTER ROLE [" + $role + "] ADD MEMBER [" + $User.name + "]"
                        }
                    }
                    "--GO"
                }
            }
            "/*********** Alter Schema's Owner ***********/"
            "USE [" + $db.Name + "]"
            "GO"
            foreach ($schema in $db.Schemas) {
                if ($schema.Name -inotin ("guest", "dbo", "INFORMATION_SCHEMA", "sys") -and ($schema.Name -notlike "NT *")) {
                    "ALTER AUTHORIZATION ON SCHEMA::[" + $schema.Name + "] TO [" + $schema.Owner + "]"
                } else {
                    "--ALTER AUTHORIZATION ON SCHEMA::[" + $schema.Name + "] TO [" + $schema.Owner + "]"
                }
            }
            "GO"
        }
    }
    
}








