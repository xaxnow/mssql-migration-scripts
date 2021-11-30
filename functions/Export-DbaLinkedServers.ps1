function Export-DbaLinkedServers {
    param(
        [Microsoft.SqlServer.Management.Smo.Server]$server
    )
    $linkedServer = $server.LinkedServers
    if ($linkedServer.count -ne 0) {
        foreach ($l in $linkedServer) {
            $linkedServer.Script()
            "GO"
        }
    }
}






