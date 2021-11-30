Set-Location $PSScriptRoot
$securePwd = ConvertTo-SecureString -String "opppd" -AsPlainText -Force
ConvertFrom-SecureString $securePwd | Set-Content ".\securePwd.txt"