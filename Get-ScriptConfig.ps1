<#
.SYNOPSIS
    Load configuration for PowerShell scripts.

.DESCRIPTION
    Loads configuration from config.json in the scripts directory.
    If config.json doesn't exist, prompts to create from example.

.EXAMPLE
    $config = Get-ScriptConfig
    $config.ssh.servers
#>

[CmdletBinding()]
param()

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path $scriptDir "config.json"
$examplePath = Join-Path $scriptDir "config.example.json"

# Check if config exists
if (-not (Test-Path $configPath)) {
    Write-Host ""
    Write-Host "Configuration file not found!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To set up your configuration:" -ForegroundColor Cyan
    Write-Host "  1. Copy config.example.json to config.json" -ForegroundColor White
    Write-Host "  2. Edit config.json with your settings" -ForegroundColor White
    Write-Host ""
    
    if (Test-Path $examplePath) {
        Write-Host "Would you like to create config.json from the example now? (Y/N): " -NoNewline -ForegroundColor Yellow
        $response = Read-Host
        
        if ($response -eq 'Y' -or $response -eq 'y') {
            Copy-Item $examplePath $configPath
            Write-Host ""
            Write-Host "Created config.json - please edit it with your settings." -ForegroundColor Green
            Write-Host "Location: $configPath" -ForegroundColor Gray
            Write-Host ""
            
            # Open in editor if available
            if (Get-Command notepad -ErrorAction SilentlyContinue) {
                Start-Process notepad $configPath
            }
        }
    }
    
    return $null
}

# Load and parse config
try {
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
    return $config
} catch {
    Write-Host "Error loading config.json: $($_.Exception.Message)" -ForegroundColor Red
    return $null
}
