function Export-DbaCredentials {
    param(
        [Microsoft.SqlServer.Management.Smo.Server]$server
    )
    system.
    $CreationScriptOptions = new-object -typeName "Microsoft.SqlServer.Management.Smo.ScriptingOptions"
    $CreationScriptOptions.ContinueScriptingOnError = $true
    $Credentials = $server.Credentials 
    if ($Credentials.Count -ne 0) {
        foreach ($c in $Credentials) {
            "CREATE CREDENTIALS [" + $C.NAME + "] WITH IDENTITY =N'" + $C.IDENTITY + "', SECRET = N'password'"
            "GO"
        }
    }
    
}





