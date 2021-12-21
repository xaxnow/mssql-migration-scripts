
$ShellDir = $PSScriptRoot
Get-ChildItem $ShellDir\functions | ForEach-Object { . $_.FullName }
$FileDate = Get-Date -Format "yyyyMMdd_HHmmss"
$LocalDataPath = Join-Path $ShellDir "data"
"Local Path For All Instance Information : " + $LocalDataPath
$existLocalDataPath = Test-Path $LocalDataPath
if ($existLocalDataPath -eq $false) {
    New-Item -Path $LocalDataPath -ItemType Directory
}
$srv 
Set-Location $PSScriptRoot
$user = 'sql_user'
$securitypwd = Get-Content '.\securePwd.txt' | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential($user, $securitypwd)
$instanceInfoFile = Join-Path -Path $ShellDir -ChildPath 'instanceInfo.txt'
$instances = Get-Content -Path $instanceInfoFile
ForEach ($i in $instances) {
    $arr = $i -split ","
    $instance = $arr[0] + "," + $arr[1]
    
    if ($arr[2] -eq "" -or $arr[3] -eq "") {
        try {
            $srv = Connect-DbaInstanceWithCredential -Instance $instance -Cred $Cred
        } catch {
            
            $errorMsg = "Error [Credential]: Can't connect to " + $instance + " . Please check user & Password ."
            Write-Warning $errorMsg
        }
    } elseif ($arr[2] -ne "" -or $arr[3] -ne "") {
        try {
            $srv = Connect-DbaInstanceWithLogin -Instance $instance -u $arr[2] -p $arr[3]
        } catch {
            $errorMsg = "Error [InstanceInfo.txt]: Can't connect to " + $instance + " . Please check user & Password ."
            Write-Warning $errorMsg
        }
    } 

    $instancePath = $LocalDataPath + "\" + $instance + "_" + $srv.ComputerNamePhysicalNetBIOS + '$' + $srv.ServiceName
    if ($srv.ServiceName -eq "" -or $null -eq $srv.ServiceName) {
        Write-Warning "Connection Error"
    } else {
        "------" + $instance + "------"
        "Local Path For Specified Instance Information : " + $instancePath
    
        $basePath = $instancePath + "\" + $instance + "_"
        if ((Test-Path -Path $instancePath) -eq $false) {
            New-Item -Path $instancePath -ItemType Directory
        }
    
    
        #files name for save information
        $DbaServerRoles = $basePath + "DbaServerRoles_" + $FileDate + ".sql"
        $DbaLogins = $basePath + "DbaLogins_" + $FileDate + ".sql"
        # $DbaAgentProxyAccounts = $basePath + "DbaAgentProxyAccounts_" + $FileDate + ".sql"
        $DbaCredentials = $basePath + "DbaCredentials_" + $FileDate + ".sql"
        $DbaLinkedServers = $basePath + "DbaLinkedServers_" + $FileDate + ".sql"
        $DbaMails = $basePath + "DbaMails_" + $FileDate + ".sql"
        $DbaAgentJobsSQL = $basePath + "DbaAgentJobs_SQL_" + $FileDate + ".sql"
        $DbaAgentJobsWin = $basePath + "DbaAgentJobs_Win_" + $FileDate + ".sql"
        $DbaMasterObjects = $basePath + "DbaMasterObjects_" + $FileDate + ".sql"
        #get information & save it to files
        $ServerRoles = Export-DbaServerRoles -Server $srv 
        if ($null -ne $ServerRoles) {
            "Exporting Server Roles"
            $ServerRoles > $DbaServerRoles
        }
        "Exporting Logins"
        Export-DbaLogins -Server $srv -path $DbaLogins 
        # if ($null -ne $Logins) {
        #     "Exporting Logins"
        #     $Logins > $DbaLogins
        }
        # $SystemDBUser = Export-DbaSystemDBUser -Server $srv 
        # if ($null -ne $SystemDBUser) {
        #     "Exporting System Databases User"
        #     $SystemDBUser >> $DbaLogins
        # }
        # $AgentProxyAccounts = Export-DbaAgentProxyAccounts -Server $srv 
        # if ($null -ne $AgentProxyAccounts ) {
        #     "Exporting Agent Proxy Accounts"
        #     $AgentProxyAccounts > $DbaAgentProxyAccounts
        # }
        $Credentials = Export-DbaCredentials -Server $srv 
        if ($null -ne $Credentials) {
            "Exporting Credentials"
            $Credentials> $DbaCredentials
        }
        $LinkedServers = Export-DbaLinkedServers -Server $srv 
        if ($null -ne $LinkedServers) {
            "Exporting Linked Servers"
            $LinkedServers > $DbaLinkedServers
        }
        $Mails = Export-DbaMails -Server $srv
        if ($null -ne $Mails) {
            "Exporting Mails"
            $Mails > $DbaMails
        }
        $AgentJobs = Export-DbaAgentJobsSQL -Server $srv
        if ($null -ne $AgentJobs) {
            "Exporting Agent Jobs (Owner: SQL Login)"
            $AgentJobs > $DbaAgentJobsSQL
        }
        $AgentJobs = Export-DbaAgentJobsWin -Server $srv
        if ($null -ne $AgentJobs) {
            "Exporting Agent Jobs (Owner: Win Login)"
            $AgentJobs > $DbaAgentJobsWin
        }
        $MasterObjects = Export-DbaMasterObjects -Server $srv
        if ($null -ne $MasterObjects) {
            "Exporting Tables & Stored Procedure In Master Database"
            $MasterObjects > $DbaMasterObjects
        }
    }
    


# "Copying Files"
Copy-DbaFiles -srcPath $LocalDataPath
remove-ExpiredLogFile -Name "SMO_Object" -path $ShellDir
remove-localFile -source $LocalDataPath



