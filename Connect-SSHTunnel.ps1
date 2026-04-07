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

# Load config
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$scriptDir\Get-ScriptConfig.ps1"
$config = Get-ScriptConfig

if (-not $config) {
    Write-Host "Please configure config.json before using SSH commands." -ForegroundColor Red
    exit 1
}

# Get servers from config
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

# Get database ports from config
$dbPorts = @{}
if ($config.ssh.databasePorts) {
    foreach ($key in $config.ssh.databasePorts.PSObject.Properties.Name) {
        $dbPorts[$key] = $config.ssh.databasePorts.$key
    }
}

# If RemotePort is passed as a named DB type, resolve it
if ($dbPorts.ContainsKey($RemotePort.ToLower())) {
    $RemotePort = $dbPorts[$RemotePort.ToLower()]
    if ($LocalPort -eq 0) {
        $LocalPort = $RemotePort
    }
}
else {
    # Try to parse as integer
    try {
        $RemotePort = [int]$RemotePort
    }
    catch {
        Write-Host "Invalid port: $RemotePort" -ForegroundColor Red
        Write-Host "Use a port number or one of: $($dbPorts.Keys -join ', ')" -ForegroundColor Yellow
        exit 1
    }
}

# Set local port if not specified
if ($LocalPort -eq 0) {
    $LocalPort = $RemotePort
}

# Resolve hostname, key file, and user
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

# Get credentials directory
$credsDir = Join-Path $scriptDir "creds"

# Check for key file authentication
$keyFilePath = $null
if ($keyFile) {
    # Support both absolute paths and relative paths (in creds directory)
    if ([System.IO.Path]::IsPathRooted($keyFile)) {
        $keyFilePath = $keyFile
    }
    else {
        $keyFilePath = Join-Path $credsDir $keyFile
    }
    if (-not (Test-Path $keyFilePath)) {
        Write-Host "Key file not found: $keyFilePath" -ForegroundColor Red
        exit 1
    }
}

# Get password credentials (not needed if using key file)
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
        exit 1
    }

    $cred = Import-Clixml $credPath
    $username = $cred.UserName
    $password = $cred.GetNetworkCredential().Password
}
else {
    # For key file auth, we need a username from config or credential file
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
        exit 1
    }
}

Write-Host "Tunnel: localhost:$LocalPort -> ${RemoteHost}:${RemotePort} (via $Server)" -ForegroundColor Cyan

# Use WSL with sshpass for the tunnel
$useWSL = $false
$wsl = Get-Command wsl -ErrorAction SilentlyContinue
if ($wsl) {
    # Check if WSL has a distribution installed
    $wslCheck = wsl echo "ok" 2>&1
    if ($wslCheck -eq "ok") {
        $useWSL = $true
    }
}
if ($useWSL) {
    if ($keyFile) {
        $escapedPath = $keyFilePath -replace '\\', '/'
        $wslKeyPath = (wsl wslpath -u "'$escapedPath'").Trim()
        wsl bash -c "ssh -o StrictHostKeyChecking=no -o IdentitiesOnly=yes -i '$wslKeyPath' -N -L ${LocalPort}:${RemoteHost}:${RemotePort} $username@$Server"
    }
    else {
        $hasSshpass = wsl bash -c "command -v sshpass >/dev/null 2>&1 && echo 'yes' || echo 'no'"
        if ($hasSshpass -match 'no') {
            Write-Host "Installing sshpass in WSL..." -ForegroundColor Yellow
            wsl bash -c "sudo apt-get update && sudo apt-get install -y sshpass"
        }
        wsl bash -c "SSHPASS='$password' sshpass -e ssh -o StrictHostKeyChecking=no -N -L ${LocalPort}:${RemoteHost}:${RemotePort} $username@$Server"
    }
}
else {
    $nativeSsh = Get-Command ssh.exe -ErrorAction SilentlyContinue
    if ($nativeSsh) {
        $sshArgs = @(
            "-o", "StrictHostKeyChecking=no",
            "-o", "IdentitiesOnly=yes",
            "-N",
            "-L", "${LocalPort}:${RemoteHost}:${RemotePort}"
        )
        if ($keyFile) {
            $sshArgs += @("-i", $keyFilePath)
        }
        $sshArgs += "$username@$Server"
        
        & ssh.exe @sshArgs
    }
    else {
        # Fallback to Posh-SSH
        try {
            Import-Module Posh-SSH -ErrorAction Stop
            if ($keyFile) {
                $session = New-SSHSession -ComputerName $Server -KeyFile $keyFilePath -AcceptKey
            }
            else {
                $session = New-SSHSession -ComputerName $Server -Credential $cred -AcceptKey
            }
            
            $tunnel = New-SSHLocalPortForward -SSHSession $session -BoundHost "127.0.0.1" -BoundPort $LocalPort -RemoteAddress $RemoteHost -RemotePort $RemotePort
            Start-Sleep -Seconds 999999
            
        }
        catch {
            Write-Host "Tunnel setup failed: $($_.Exception.Message)" -ForegroundColor Red
            exit 1
        }
        finally {
            if ($session) {
                Remove-SSHSession -SessionId $session.SessionId | Out-Null
            }
        }
    }
}
