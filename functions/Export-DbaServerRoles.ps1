function Export-DbaServerRoles {
    param (
        [Microsoft.SqlServer.Management.Smo.Server]$server
    )

    $roles = $server.Roles
    foreach ($r in $roles) {
        if ($r.isFixedRole -ne $true -and $r.Name -ne "public") {
            "CREATE SERVER ROLE [" + $r.Name + "] AUTHORIZATION [" + $r.Owner + "]"
            if ($server.EnumServerPermissions().Count -gt 0) {
                $permission = $server.EnumServerPermissions()
                foreach ($grantee in $permission) {
                    if ($grantee.GranteeType -eq "ServerRole" -and $grantee.Grantee -eq $r.Name) {
                        # Add-Member -InputObject $grantee -Name "Owner" -Value $r.Owner -MemberType NoteProperty
                        # $grantee
                        $grant = switch ($grantee.PermissionState) {
                            "Grant" { "" }
                            "GrantWithGrant" { "WITH GRANT OPTION" }
                            "Deny" { "DENY" }
                        }
                        if ($grant -eq "DENY") {
                            $GrantServerRoleScript = "use [master] `r`nGO`r`nDENY " + $grantee.PermissionType + " TO [" + $grantee.Grantee + "] `r`nGO"
                            $GrantServerRoleScript
                        } else {
                            $GrantServerRoleScript = "use [master] `r`nGO`r`nGRANT " + $grantee.PermissionType + " TO [" + $grantee.Grantee + "] " + $grant + "`r`nGO"
                            $GrantServerRoleScript
                        }
                    }
                }
            }
            
        }
    }
}

