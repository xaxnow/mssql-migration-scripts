function Export-DbaAgentProxyAccounts {
    param(
        [Microsoft.SqlServer.Management.Smo.Server]$server
    )
    
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Management.Smo.ScriptingOptions") | Out-Null
    $CreationScriptOptions = new-object -typeName "Microsoft.SqlServer.Management.Smo.ScriptingOptions"
    $CreationScriptOptions.ContinueScriptingOnError = $true
    $jobProxyAccount = $server.Jobserver.ProxyAccounts
    if ($jobProxyAccount.count -ne 0) {  
        $account.Script($CreationScriptOptions)
        "GO"
    }
}






