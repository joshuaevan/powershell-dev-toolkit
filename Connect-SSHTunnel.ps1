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
if ($config.ssh.servers) {
    foreach ($key in $config.ssh.servers.PSObject.Properties.Name) {
        $servers[$key] = $config.ssh.servers.$key.hostname
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

# Resolve hostname
if ($servers.ContainsKey($Target)) {
    $Server = $servers[$Target]
} else {
    $Server = $Target
}

# Get credentials
$credsDir = Join-Path $scriptDir "creds"
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
    exit 1
}

$cred = Import-Clixml $credPath
$username = $cred.UserName
$password = $cred.GetNetworkCredential().Password

Write-Host "Setting up SSH tunnel..." -ForegroundColor Cyan
Write-Host "  Local:  127.0.0.1:$LocalPort" -ForegroundColor Green
Write-Host "  Remote: ${RemoteHost}:${RemotePort} (via $Server)" -ForegroundColor Green
Write-Host ""
Write-Host "Press Ctrl+C to close the tunnel" -ForegroundColor Yellow
Write-Host ""

# Use WSL with sshpass for the tunnel
$wsl = Get-Command wsl -ErrorAction SilentlyContinue
if ($wsl) {
    # Check if sshpass is installed
    $hasSshpass = wsl bash -c "command -v sshpass >/dev/null 2>&1 && echo 'yes' || echo 'no'"
    if ($hasSshpass -match 'no') {
        Write-Host "Installing sshpass in WSL (one-time setup)..." -ForegroundColor Yellow
        wsl bash -c "sudo apt-get update && sudo apt-get install -y sshpass"
    }
    
    # Create SSH tunnel using sshpass through WSL
    wsl bash -c "SSHPASS='$password' sshpass -e ssh -o StrictHostKeyChecking=no -N -L ${LocalPort}:${RemoteHost}:${RemotePort} $username@$Server"
} else {
    # Fallback to Posh-SSH
    try {
        Import-Module Posh-SSH -ErrorAction Stop
        $session = New-SSHSession -ComputerName $Server -Credential $cred -AcceptKey
        
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
