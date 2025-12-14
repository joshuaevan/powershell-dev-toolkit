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
} else {
    # Try to parse as integer
    try {
        $RemotePort = [int]$RemotePort
    } catch {
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
} else {
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
    } else {
        $keyFilePath = Join-Path $credsDir $keyFile
    }
    if (-not (Test-Path $keyFilePath)) {
        Write-Host ""
        Write-Host "Key file not found: $keyFilePath" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "To set up SSH key authentication:" -ForegroundColor Cyan
        Write-Host "  1. Place your key file (.pem) in the creds directory:" -ForegroundColor White
        Write-Host "     Copy-Item 'C:\path\to\your-key.pem' '$keyFilePath'" -ForegroundColor Gray
        Write-Host ""
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
        Write-Host ""
        Write-Host "Credential file not found!" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "To set up SSH credentials:" -ForegroundColor Cyan
        Write-Host "  1. Create credentials directory if needed:" -ForegroundColor White
        Write-Host "     New-Item -Path '$credsDir' -ItemType Directory -Force" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  2. Store your credentials:" -ForegroundColor White
        Write-Host "     `$cred = Get-Credential -UserName 'your-ssh-username'" -ForegroundColor Gray
        Write-Host "     `$cred | Export-Clixml '$credPath'" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  Or configure a key file in config.json:" -ForegroundColor Cyan
        Write-Host '     "keyFile": "your-key.pem"' -ForegroundColor Gray
        Write-Host ""
        exit 1
    }

    $cred = Import-Clixml $credPath
    $username = $cred.UserName
    $password = $cred.GetNetworkCredential().Password
} else {
    # For key file auth, we need a username from config or credential file
    if ($configUser) {
        $username = $configUser
    } else {
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
        Write-Host ""
        Write-Host "Username required for key file authentication." -ForegroundColor Yellow
        Write-Host "Add 'user' to server config or create a credential file:" -ForegroundColor Cyan
        Write-Host "     `$cred = Get-Credential -UserName 'your-ssh-username'" -ForegroundColor Gray
        Write-Host "     `$cred | Export-Clixml '.\creds\ssh-credentials.xml'" -ForegroundColor Gray
        Write-Host ""
        exit 1
    }
}

Write-Host "Setting up SSH tunnel..." -ForegroundColor Cyan
Write-Host "  Local:  127.0.0.1:$LocalPort" -ForegroundColor Green
Write-Host "  Remote: ${RemoteHost}:${RemotePort} (via $Server)" -ForegroundColor Green
Write-Host ""
Write-Host "Press Ctrl+C to close the tunnel" -ForegroundColor Yellow
Write-Host ""

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
        # Convert Windows path to WSL path for key file
        $escapedPath = $keyFilePath -replace '\\', '/'
        $wslKeyPath = (wsl wslpath -u "'$escapedPath'").Trim()
        Write-Host "Key: $wslKeyPath" -ForegroundColor Gray
        # Create SSH tunnel using key file through WSL
        wsl bash -c "ssh -o StrictHostKeyChecking=no -o IdentitiesOnly=yes -i '$wslKeyPath' -N -L ${LocalPort}:${RemoteHost}:${RemotePort} $username@$Server"
    } else {
        # Check if sshpass is installed
        $hasSshpass = wsl bash -c "command -v sshpass >/dev/null 2>&1 && echo 'yes' || echo 'no'"
        if ($hasSshpass -match 'no') {
            Write-Host "Installing sshpass in WSL (one-time setup)..." -ForegroundColor Yellow
            wsl bash -c "sudo apt-get update && sudo apt-get install -y sshpass"
        }
        
        # Create SSH tunnel using sshpass through WSL
        wsl bash -c "SSHPASS='$password' sshpass -e ssh -o StrictHostKeyChecking=no -N -L ${LocalPort}:${RemoteHost}:${RemotePort} $username@$Server"
    }
} else {
    # Try native Windows SSH first (available in Windows 10/11)
    $nativeSsh = Get-Command ssh.exe -ErrorAction SilentlyContinue
    if ($nativeSsh) {
        Write-Host "Using native Windows SSH..." -ForegroundColor Gray
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
    } else {
        # Fallback to Posh-SSH
        try {
            Import-Module Posh-SSH -ErrorAction Stop
            if ($keyFile) {
                $session = New-SSHSession -ComputerName $Server -KeyFile $keyFilePath -AcceptKey
            } else {
                $session = New-SSHSession -ComputerName $Server -Credential $cred -AcceptKey
            }
            
            # Set up port forwarding
            $tunnel = New-SSHLocalPortForward -SSHSession $session -BoundHost "127.0.0.1" -BoundPort $LocalPort -RemoteAddress $RemoteHost -RemotePort $RemotePort
            
            Write-Host "Tunnel established. Keep this window open." -ForegroundColor Green
            Write-Host "Press Ctrl+C to close..." -ForegroundColor Yellow
            
            # Keep tunnel open
            Start-Sleep -Seconds 999999
            
        } catch {
            Write-Host "Tunnel setup failed: $($_.Exception.Message)" -ForegroundColor Red
            exit 1
        } finally {
            if ($session) {
                Remove-SSHSession -SessionId $session.SessionId | Out-Null
            }
        }
    }
}
