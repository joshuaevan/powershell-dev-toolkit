function Get-ScriptConfig {
    <#
    .SYNOPSIS
        Load configuration for PowerShell Dev Toolkit.

    .DESCRIPTION
        Loads configuration from config.json relative to the toolkit root.
        If config.json doesn't exist, prompts to create from example.

    .EXAMPLE
        $config = Get-ScriptConfig
        $config.ssh.servers
    #>
    [CmdletBinding()]
    param()

    $configPath = Join-Path $script:ToolkitRoot "config.json"
    $examplePath = Join-Path $script:ToolkitRoot "config.example.json"

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

                if (Get-Command notepad -ErrorAction SilentlyContinue) {
                    Start-Process notepad $configPath
                }
            }
        }

        return $null
    }

    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        return $config
    } catch {
        Write-Host "Error loading config.json: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}
