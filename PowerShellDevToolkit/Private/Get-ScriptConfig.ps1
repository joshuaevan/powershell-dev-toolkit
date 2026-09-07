function Get-ScriptConfig {
    <#
    .SYNOPSIS
        Load configuration for PowerShell Dev Toolkit.

    .DESCRIPTION
        Loads config.json from the toolkit data folder (see Get-ToolkitPaths).
        Returns $null when the file is missing or cannot be parsed.

    .PARAMETER Quiet
        Suppress all host output. Use from tab completers and from commands
        that only need the config if it happens to exist.

    .EXAMPLE
        $config = Get-ScriptConfig
        $config.ssh.servers
    #>
    [CmdletBinding()]
    param(
        [switch]$Quiet
    )

    $configPath = (Get-ToolkitPaths).ConfigPath

    if (-not (Test-Path $configPath)) {
        if (-not $Quiet) {
            Write-Host ""
            Write-Host "Configuration file not found: $configPath" -ForegroundColor Yellow
            Write-Host "Run " -NoNewline -ForegroundColor Cyan
            Write-Host "Initialize-Toolkit" -NoNewline -ForegroundColor Yellow
            Write-Host " to create it." -ForegroundColor Cyan
            Write-Host ""
        }
        return $null
    }

    try {
        return (Get-Content $configPath -Raw | ConvertFrom-Json)
    } catch {
        if (-not $Quiet) {
            Write-Host "Error loading config.json ($configPath): $($_.Exception.Message)" -ForegroundColor Red
        }
        return $null
    }
}
