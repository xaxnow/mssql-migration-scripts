function Export-DbaMails {
    param(
        [Microsoft.SqlServer.Management.Smo.Server]$server
    )
    $mails = $server.Mail
    if ($mails -ne 0) {
        foreach($m in $mails){
            $m.Script()
            "GO"
        }
        
    }
}





