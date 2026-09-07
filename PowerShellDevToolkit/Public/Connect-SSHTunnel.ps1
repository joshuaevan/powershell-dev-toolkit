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

    $ssh = Resolve-SSHTarget -Target $Target -Config $config
    if (-not $ssh) { return }

    $Server      = $ssh.Server
    $username    = $ssh.UserName
    $password    = $ssh.Password
    $cred        = $ssh.Credential
    $keyFilePath = $ssh.KeyFilePath
    $keyFile     = [bool]$keyFilePath

    Write-Host "Tunnel: localhost:$LocalPort -> ${RemoteHost}:${RemotePort} (via $Server)" -ForegroundColor Cyan

    $useWSL = Test-WslAvailable

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
