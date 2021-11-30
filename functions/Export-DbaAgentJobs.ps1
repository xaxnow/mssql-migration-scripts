function Export-DbaAgentJobsSQL {
    param(
        [Microsoft.SqlServer.Management.Smo.Server]$server
    )
    $jobs = $server.JobServer.Jobs
    foreach ($i in $jobs) {
        if ($i.ownerloginName -notlike "*\*") {
            if ($i.Name -eq "syspolicy_purge_history") {
                "/*********** syspolicy_purge_history don't generate ***********/"
            }
            elseif ($i.CategoryID -in (6, 18, 16, 10, 11, 12, 20, 13, 14, 19, 15, 17)) {
                "/************"
                "USE [msdb]"
                "GO"
                $i.Script()
                "GO"
                "***********/"
            }
            else {
                "USE [msdb]"
                "GO"
                $i.Script()
                "GO"
            }
        }
    }
}


function Export-DbaAgentJobsWin {
    param(
        [Microsoft.SqlServer.Management.Smo.Server]$server
    )
    $jobs = $server.JobServer.Jobs
    foreach ($i in $jobs) {
        if ($i.ownerloginName -like "*\*") {
            if ($i.CategoryID -in (6, 18, 16, 10, 11, 12, 20, 13, 14, 19, 15, 17)) {
                "/************"
                "USE [msdb]"
                "GO"
                $i.Script()
                "GO"
                "***********/"
            }
            else {
                "/*********** Please Check OwnerLoginName ***********/"
                "USE [msdb]"
                "GO"
                $i.Script()
                "GO"
            }
            
        }
        
    }
}





