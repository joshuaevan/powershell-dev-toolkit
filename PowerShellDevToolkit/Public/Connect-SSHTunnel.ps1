function Connect-SSHTunnel {
    <#
    .SYNOPSIS
        Create an SSH tunnel for database or service access.

    .PARAMETER Target
        Server alias (from config.json) or hostname.

    .PARAMETER RemotePort
        Remote port number or database type name (mysql, postgres, etc.).

    .PARAMETER LocalPort
        Local port to bind (defaults to same as remote).

    .PARAMETER RemoteHost
        Remote host for the tunnel (default: localhost).

    .EXAMPLE
        Connect-SSHTunnel myserver postgres
        tunnel myserver mysql 3307
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Target,

        [Parameter(Position = 1)]
        [string]$RemotePort = "3306",

        [Parameter(Position = 2)]
        [int]$LocalPort = 0,

        [Parameter()]
        [string]$RemoteHost = "localhost"
    )

    $config = Get-ScriptConfig

    if (-not $config) {
        Write-Host "Please configure config.json before using SSH commands." -ForegroundColor Red
        return
    }

    $servers = @{}
    $serverKeyFiles = @{}
    $serverUsers = @{}
    if ($config.ssh.servers) {
        foreach ($key in $config.ssh.servers.PSObject.Properties.Name) {
            $servers[$key] = $config.ssh.servers.$key.hostname
            if ($config.ssh.servers.$key.keyFile) {
                $serverKeyFiles[$key] = $config.ssh.servers.$key.keyFile
            }
            if ($config.ssh.servers.$key.user) {
                $serverUsers[$key] = $config.ssh.servers.$key.user
            }
        }
    }

    $dbPorts = @{}
    if ($config.ssh.databasePorts) {
        foreach ($key in $config.ssh.databasePorts.PSObject.Properties.Name) {
            $dbPorts[$key] = $config.ssh.databasePorts.$key
        }
    }

    if ($dbPorts.ContainsKey($RemotePort.ToLower())) {
        $RemotePort = $dbPorts[$RemotePort.ToLower()]
        if ($LocalPort -eq 0) {
            $LocalPort = $RemotePort
        }
    }
    else {
        try {
            $RemotePort = [int]$RemotePort
        }
        catch {
            Write-Host "Invalid port: $RemotePort" -ForegroundColor Red
            Write-Host "Use a port number or one of: $($dbPorts.Keys -join ', ')" -ForegroundColor Yellow
            return
        }
    }

    if ($LocalPort -eq 0) {
        $LocalPort = $RemotePort
    }

    $keyFile = $null
    $configUser = $null
    if ($servers.ContainsKey($Target)) {
        $Server = $servers[$Target]
        if ($serverKeyFiles.ContainsKey($Target)) {
            $keyFile = $serverKeyFiles[$Target]
        }
        if ($serverUsers.ContainsKey($Target)) {
            $configUser = $serverUsers[$Target]
        }
    }
    else {
        $Server = $Target
    }

    $credsDir = Join-Path $script:ToolkitRoot "creds"

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
            return
        }
    }

    $username = $null
    $password = $null
    $cred = $null

    if (-not $keyFile) {
        $credFile = $config.ssh.credentialFile
        if (-not $credFile) {
            $credFile = "ssh-credentials.xml"
        }
        $credPath = Join-Path $credsDir $credFile

        if (-not (Test-Path $credPath)) {
            Write-Host "Credential file not found: $credPath" -ForegroundColor Red
            return
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
            $credFile = $config.ssh.credentialFile
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
            return
        }
    }

    Write-Host "Tunnel: localhost:$LocalPort -> ${RemoteHost}:${RemotePort} (via $Server)" -ForegroundColor Cyan

    $useWSL = $false
    $wsl = Get-Command wsl -ErrorAction SilentlyContinue
    if ($wsl) {
        $wslCheck = wsl echo "ok" 2>&1
        if ($wslCheck -eq "ok") {
            $useWSL = $true
        }
    }

    if ($keyFile) {
        $winSsh = Get-Command ssh.exe -ErrorAction SilentlyContinue
        if ($winSsh) {
            & ssh.exe -o StrictHostKeyChecking=no -o IdentitiesOnly=yes -i $keyFilePath -N -L "${LocalPort}:${RemoteHost}:${RemotePort}" "$username@$Server"
        }
        elseif ($useWSL) {
            $escapedPath = $keyFilePath -replace '\\', '/'
            $wslKeyPath = (wsl wslpath -u "'$escapedPath'").Trim()
            wsl bash -c "ssh -o StrictHostKeyChecking=no -o IdentitiesOnly=yes -i '$wslKeyPath' -N -L ${LocalPort}:${RemoteHost}:${RemotePort} $username@$Server"
        }
        else {
            try {
                Import-Module Posh-SSH -ErrorAction Stop
                $session = New-SSHSession -ComputerName $Server -KeyFile $keyFilePath -AcceptKey
                New-SSHLocalPortForward -SSHSession $session -BoundHost "127.0.0.1" -BoundPort $LocalPort -RemoteAddress $RemoteHost -RemotePort $RemotePort | Out-Null
                Start-Sleep -Seconds 999999
            }
            catch {
                Write-Host "Tunnel setup failed: $($_.Exception.Message)" -ForegroundColor Red
                return
            }
            finally {
                if ($session) {
                    Remove-SSHSession -SessionId $session.SessionId | Out-Null
                }
            }
        }
    }
    elseif ($useWSL) {
        $hasSshpass = wsl bash -c "command -v sshpass >/dev/null 2>&1 && echo 'yes' || echo 'no'"
        if ($hasSshpass -match 'no') {
            Write-Host "Installing sshpass in WSL..." -ForegroundColor Yellow
            wsl bash -c "sudo apt-get update && sudo apt-get install -y sshpass"
        }
        wsl bash -c "SSHPASS='$password' sshpass -e ssh -o StrictHostKeyChecking=no -N -L ${LocalPort}:${RemoteHost}:${RemotePort} $username@$Server"
    }
    else {
        $nativeSsh = Get-Command ssh.exe -ErrorAction SilentlyContinue
        if ($nativeSsh) {
            $sshArgs = @(
                "-o", "StrictHostKeyChecking=no",
                "-o", "IdentitiesOnly=yes",
                "-N",
                "-L", "${LocalPort}:${RemoteHost}:${RemotePort}",
                "$username@$Server"
            )
            & ssh.exe @sshArgs
        }
        else {
            try {
                Import-Module Posh-SSH -ErrorAction Stop
                $session = New-SSHSession -ComputerName $Server -Credential $cred -AcceptKey
                New-SSHLocalPortForward -SSHSession $session -BoundHost "127.0.0.1" -BoundPort $LocalPort -RemoteAddress $RemoteHost -RemotePort $RemotePort | Out-Null
                Start-Sleep -Seconds 999999
            }
            catch {
                Write-Host "Tunnel setup failed: $($_.Exception.Message)" -ForegroundColor Red
                return
            }
            finally {
                if ($session) {
                    Remove-SSHSession -SessionId $session.SessionId | Out-Null
                }
            }
        }
    }
}
