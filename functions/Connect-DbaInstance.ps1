function Connect-DbaInstance {
    [cmdletBinding()]
    param (
        [string]$instance
    )
    [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Smo') | Out-Null
    $srv = New-Object ('Microsoft.SqlServer.Management.Smo.server') $instance
    $srv.ConnectionContext.ConnectTimeout = 5
    $srv.ConnectionContext.ApplicationName = "SQL Management By Powershell" 
    # $srv.ConnectionContext.AutoDisconnectMode = 0 #after statement is executed if connection is pooled disconnect connection
    $srv.ConnectionContext.Connect()
    $srv
}

function Connect-DbaInstanceWithLogin {
    [cmdletBinding()]
    param (
        [string]$instance,
        [string]$u,
        [string]$p
    )
    [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Smo') | Out-Null
    $srv = New-Object ('Microsoft.SqlServer.Management.Smo.server') $instance
    $srv.ConnectionContext.ConnectTimeout = 5
    $srv.ConnectionContext.ApplicationName = "SQL Management By Powershell" 
    $srv.ConnectionContext.AutoDisconnectMode = 0 #after statement is executed if connection is pooled disconnect connection
    $srv.ConnectionContext.LoginSecure = $false
    $srv.ConnectionContext.Login = $u
    $srv.ConnectionContext.Password = $p
    $srv.ConnectionContext.Connect()
    $srv
    
}
function Connect-DbaInstanceWithCredential {
    [cmdletBinding()]
    param (
        [string]$instance,
        [pscredential]$Cred
    )
    [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Smo') | Out-Null
    $srv = New-Object ('Microsoft.SqlServer.Management.Smo.server') $instance
    $srv.ConnectionContext.ConnectTimeout = 5
    $srv.ConnectionContext.ApplicationName = "SQL Management By Powershell" 
    $srv.ConnectionContext.AutoDisconnectMode = 0 #after statement is executed if connection is pooled disconnect connection
    $srv.ConnectionContext.LoginSecure = $false
    $srv.ConnectionContext.Login = $Cred.UserName
    $srv.ConnectionContext.Password = $Cred.GetNetworkCredential().Password
    $srv.ConnectionContext.Connect()
    $srv
    
}

