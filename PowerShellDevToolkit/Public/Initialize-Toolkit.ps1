function Initialize-Toolkit {
    <#
    .SYNOPSIS
        First-run setup: create the data folder, config.json and creds folder.

    .DESCRIPTION
        Works for both git-clone and PowerShell Gallery installs. Creates the
        toolkit data folder (see Get-ToolkitPaths), copies config.example.json
        to config.json when it does not exist, creates the creds folder, and
        opens config.json in your editor.

    .PARAMETER Force
        Replace an existing config.json with the example.

    .PARAMETER NoOpen
        Do not open config.json in the editor afterwards.

    .EXAMPLE
        Initialize-Toolkit
    .EXAMPLE
        Initialize-Toolkit -NoOpen
    .EXAMPLE
        Initialize-Toolkit -Force
    #>
    [CmdletBinding()]
    param(
        [switch]$Force,
        [switch]$NoOpen
    )

    $paths = Get-ToolkitPaths

    foreach ($dir in @($paths.DataRoot, $paths.CredsPath)) {
        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Write-Host "Created folder: $dir" -ForegroundColor Green
        }
    }

    if (-not (Test-Path $paths.ExampleConfigPath)) {
        Write-Host "Example config not found: $($paths.ExampleConfigPath)" -ForegroundColor Red
        return
    }

    $configExisted = Test-Path $paths.ConfigPath
    if ($configExisted -and -not $Force) {
        Write-Host "Config already exists: $($paths.ConfigPath)" -ForegroundColor Yellow
        Write-Host "Use -Force to replace it with the example." -ForegroundColor Gray
    } else {
        Copy-Item $paths.ExampleConfigPath $paths.ConfigPath -Force
        $verb = if ($configExisted) { 'Replaced' } else { 'Created' }
        Write-Host "$verb config: $($paths.ConfigPath)" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "PowerShell Dev Toolkit" -ForegroundColor Cyan
    Write-Host "  Install type: " -NoNewline -ForegroundColor Gray
    Write-Host $paths.InstallType -ForegroundColor White
    Write-Host "  Data folder:  " -NoNewline -ForegroundColor Gray
    Write-Host $paths.DataRoot -ForegroundColor White
    Write-Host "  Config:       " -NoNewline -ForegroundColor Gray
    Write-Host $paths.ConfigPath -ForegroundColor White
    Write-Host "  Credentials:  " -NoNewline -ForegroundColor Gray
    Write-Host $paths.CredsPath -ForegroundColor White
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Edit config.json and add your SSH servers" -ForegroundColor White
    Write-Host "  2. Run " -NoNewline -ForegroundColor White
    Write-Host "New-SSHCredential" -NoNewline -ForegroundColor Yellow
    Write-Host " to store your SSH username and password" -ForegroundColor White
    Write-Host "  3. Run " -NoNewline -ForegroundColor White
    Write-Host "helpme" -NoNewline -ForegroundColor Yellow
    Write-Host " to see all commands" -ForegroundColor White
    Write-Host ""

    if (-not $NoOpen) {
        Edit-File $paths.ConfigPath
    }
}
