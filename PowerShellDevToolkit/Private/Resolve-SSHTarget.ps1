function Resolve-SSHTarget {
    <#
    .SYNOPSIS
        Resolve a server alias or hostname into SSH connection details.

    .DESCRIPTION
        Looks the target up in config.ssh.servers, resolves the key file (if
        any) under the creds folder, and loads the credential file for the
        username and password. Prints an error and returns $null when a
        required file is missing.

    .PARAMETER Target
        Server alias from config.json, or a raw hostname.

    .PARAMETER Config
        The object returned by Get-ScriptConfig.

    .OUTPUTS
        PSCustomObject with Server, UserName, Password, Credential, KeyFilePath.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Target,

        [Parameter(Mandatory = $true)]
        $Config
    )

    $servers = @{}
    $serverKeyFiles = @{}
    $serverUsers = @{}
    if ($Config.ssh -and $Config.ssh.servers) {
        foreach ($key in $Config.ssh.servers.PSObject.Properties.Name) {
            $servers[$key] = $Config.ssh.servers.$key.hostname
            if ($Config.ssh.servers.$key.keyFile) {
                $serverKeyFiles[$key] = $Config.ssh.servers.$key.keyFile
            }
            if ($Config.ssh.servers.$key.user) {
                $serverUsers[$key] = $Config.ssh.servers.$key.user
            }
        }
    }

    $keyFile = $null
    $configUser = $null
    if ($servers.ContainsKey($Target)) {
        $server = $servers[$Target]
        if ($serverKeyFiles.ContainsKey($Target)) {
            $keyFile = $serverKeyFiles[$Target]
        }
        if ($serverUsers.ContainsKey($Target)) {
            $configUser = $serverUsers[$Target]
        }
    }
    else {
        $server = $Target
    }

    $credsDir = (Get-ToolkitPaths).CredsPath

    $keyFilePath = $null
    if ($keyFile) {
        if ([System.IO.Path]::IsPathRooted($keyFile)) {
            $keyFilePath = $keyFile
        }
        else {
            $keyFilePath = Join-Path $credsDir $keyFile
        }
        if (-not (Test-Path $keyFilePath)) {
            Write-Host "Key file not found: $keyFilePath" -ForegroundColor Red
            return $null
        }
    }

    $username = $null
    $password = $null
    $cred = $null

    $credFile = $null
    if ($Config.ssh) { $credFile = $Config.ssh.credentialFile }

    if (-not $keyFile) {
        if (-not $credFile) {
            $credFile = "ssh-credentials.xml"
        }
        $credPath = Join-Path $credsDir $credFile

        if (-not (Test-Path $credPath)) {
            Write-Host "Credential file not found: $credPath" -ForegroundColor Red
            return $null
        }

        $cred = Import-Clixml $credPath
        $username = $cred.UserName
        $password = $cred.GetNetworkCredential().Password
    }
    else {
        if ($configUser) {
            $username = $configUser
        }
        else {
            if ($credFile) {
                $credPath = Join-Path $credsDir $credFile
                if (Test-Path $credPath) {
                    $cred = Import-Clixml $credPath
                    $username = $cred.UserName
                }
            }
        }

        if (-not $username) {
            Write-Host "Username required. Add 'user' to server config in config.json" -ForegroundColor Red
            return $null
        }
    }

    return [pscustomobject]@{
        Server      = $server
        UserName    = $username
        Password    = $password
        Credential  = $cred
        KeyFilePath = $keyFilePath
    }
}
