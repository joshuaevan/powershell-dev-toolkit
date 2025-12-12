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
if ($config.ssh.servers) {
    foreach ($key in $config.ssh.servers.PSObject.Properties.Name) {
        $servers[$key] = $config.ssh.servers.$key.hostname
    }
}

# Resolve hostname
if ($servers.ContainsKey($Target)) {
    $Server = $servers[$Target]
} else {
    $Server = $Target
}

# Try Posh-SSH first if WSL not available
$useWSL = $true
$wsl = Get-Command wsl -ErrorAction SilentlyContinue
if (-not $wsl) {
    $useWSL = $false
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

# Use WSL with sshpass for proper terminal handling
if ($useWSL) {
    # Check if sshpass is installed
    $hasSshpass = wsl bash -c "command -v sshpass >/dev/null 2>&1 && echo 'yes' || echo 'no'"
    if ($hasSshpass -match 'no') {
        Write-Host "Installing sshpass in WSL (one-time setup)..." -ForegroundColor Yellow
        wsl bash -c "sudo apt-get update && sudo apt-get install -y sshpass"
    }
    
    # Connect using sshpass through WSL (proper terminal handling)
    wsl bash -c "SSHPASS='$password' sshpass -e ssh -o StrictHostKeyChecking=no $username@$Server"
} else {
    # Fallback to Posh-SSH
    Write-Host "Connecting to $Server as $username..." -ForegroundColor Cyan
    try {
        $session = New-SSHSession -ComputerName $Server -Credential $cred -AcceptKey
        Invoke-SSHCommand -SessionId $session.SessionId -Command "bash -l" -TimeOut 3600
        Remove-SSHSession -SessionId $session.SessionId | Out-Null
    } catch {
        Write-Host "Connection failed: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}
