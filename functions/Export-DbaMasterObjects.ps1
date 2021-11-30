function Export-DbaMasterObjects {
    param(
        [Microsoft.SqlServer.Management.Smo.Server]$server
    )
    $databases = $server.Databases
    foreach ($db in $databases) {
        if ($db.Name -eq "master") {
            
            foreach ($t in $db.Tables) {
                if ($t.Schema -eq "dbo" -and $t.isSystemObject -eq $false) {
                    "USE [master]"
                    "GO"
                    $t.Script()
                    "GO"
                }
            }
            foreach ($sp in $db.StoredProcedures) {
                if ($sp.Schema -eq "dbo" -and $sp.isSystemObject -eq $false) {
                    "USE [master]"
                    "GO"
                    "SET ANSI_NULLS ON"
                    "GO"
                    "SET QUOTED_IDENTIFIER ON"
                    "GO"
                    $sp.TextHeader
                    $sp.TextBody
                    "GO"
                }
            }
        }
    }
}





