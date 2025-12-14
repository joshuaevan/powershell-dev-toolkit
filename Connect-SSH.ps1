param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Target
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

# Try Posh-SSH first if WSL not available
$useWSL = $false
$wsl = Get-Command wsl -ErrorAction SilentlyContinue
if ($wsl) {
    # Check if WSL has a distribution installed
    $wslCheck = wsl echo "ok" 2>&1
    if ($wslCheck -eq "ok") {
        $useWSL = $true
    }
}
if (-not $useWSL) {
    # Use Posh-SSH
    try {
        Import-Module Posh-SSH -ErrorAction Stop
    } catch {
        Write-Host "Neither WSL nor Posh-SSH is available." -ForegroundColor Red
        Write-Host "Install WSL: wsl --install" -ForegroundColor Yellow
        Write-Host "Or install Posh-SSH: Install-Module -Name Posh-SSH" -ForegroundColor Yellow
        exit 1
    }
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

# Use WSL with sshpass for proper terminal handling
if ($useWSL) {
    if ($keyFile) {
        # Convert Windows path to WSL path for key file
        $escapedPath = $keyFilePath -replace '\\', '/'
        $wslKeyPath = (wsl wslpath -u "'$escapedPath'").Trim()
        Write-Host "Connecting to $Server as $username (using key file)..." -ForegroundColor Cyan
        Write-Host "Key: $wslKeyPath" -ForegroundColor Gray
        wsl bash -c "ssh -o StrictHostKeyChecking=no -o IdentitiesOnly=yes -i '$wslKeyPath' $username@$Server"
    } else {
        # Check if sshpass is installed
        $hasSshpass = wsl bash -c "command -v sshpass >/dev/null 2>&1 && echo 'yes' || echo 'no'"
        if ($hasSshpass -match 'no') {
            Write-Host "Installing sshpass in WSL (one-time setup)..." -ForegroundColor Yellow
            wsl bash -c "sudo apt-get update && sudo apt-get install -y sshpass"
        }
        
        # Connect using sshpass through WSL (proper terminal handling)
        wsl bash -c "SSHPASS='$password' sshpass -e ssh -o StrictHostKeyChecking=no $username@$Server"
    }
} else {
    # Fallback to Posh-SSH
    Write-Host "Connecting to $Server as $username..." -ForegroundColor Cyan
    try {
        if ($keyFile) {
            $session = New-SSHSession -ComputerName $Server -KeyFile $keyFilePath -AcceptKey
        } else {
            $session = New-SSHSession -ComputerName $Server -Credential $cred -AcceptKey
        }
        Invoke-SSHCommand -SessionId $session.SessionId -Command "bash -l" -TimeOut 3600
        Remove-SSHSession -SessionId $session.SessionId | Out-Null
    } catch {
        Write-Host "Connection failed: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}
