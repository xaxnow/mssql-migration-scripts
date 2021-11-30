function Copy-DbaFiles {
    param(
        [string]$srcPath,
        [string]$SMO_Path_PSDrivePath = "\\localhost\MSSQL_BACKUP",
        [string]$nasUser = "user"
        # [string]$nasPwd
    )
    # $PWord = Get-Content securityString.txt | ConvertTo-SecureString
    $PWord = ConvertTo-SecureString -String 'password' -AsPlainText -Force
    # $PWord | Out-File securityString.txt
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $NasUser, $PWord
    new-psdrive -Name 'SMO_Path' -Psprovider FileSystem -Root $SMO_Path_PSDrivePath -Credential $Credential -ErrorAction "stop"
    
    
    $destPath = $SMO_Path_PSDrivePath + "\SMOOBJ\"
    "Shared Path For Instance Information: " + $destPath
    $exist = Test-Path  $destPath
    if ($exist -eq $false) {
        New-Item -Path $destPath -ItemType Directory
    }

    $logDate = Get-Date -Format 'yyyyMMdd'
    $logFile = "SMO_Object" + '$CopyFile_' + $logDate + '.log'
    # Copy Files
    Robocopy.exe $srcPath $destPath $FileType /E /NS /NP /NJH /PURGE /UNILOG+:$logFile
        
}



function remove-ExpiredLogFile {
    param (
        [string]$Name,
        [string]$path,
        [int]$FileExpiredDays = -10
    )
    $expiredDate = (Get-Date).AddDays($FileExpiredDays)
    $LogFilePrefix = $Name + '$CopyFile_'
    if (Test-Path -Path $path -PathType Container) {
        $items = Get-ChildItem $path
        $items | ForEach-Object {
            if ($_.BaseName -ilike $LogFilePrefix + "*") {
                if ($_.LastWriteTime -lt $expiredDate) {
                    Remove-Item $_.FullName -Force
                    $fileName = $_.FullName
                    Write-Output "Removed Log File: $fileName" 
                }
            } 
        }
    } 
}

function remove-localFile {
    param (
        [string]$source,
        [int]$FileExpiredDays = -10
    )
    $expiredDate = (Get-Date).AddDays($FileExpiredDays)
    $items = Get-ChildItem -Path $source -Recurse
    $items | ForEach-Object {
        if (Test-Path -Path $_.FullName -PathType Leaf) {
            if ($_.LastWriteTime -lt $expiredDate) {
                Remove-Item $_.FullName -Force
                $fileName = $_.FullName
                Write-Output "Removed File: $fileName" 
            }
        }       
    }
    
}



