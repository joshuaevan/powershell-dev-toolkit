function Update-Toolkit {
    <#
    .SYNOPSIS
        Self-update the PowerShell Dev Toolkit from its git remote.

    .DESCRIPTION
        Pulls the latest changes from the toolkit's git repository, shows a
        summary of what changed, and re-imports the module so new commands and
        aliases take effect immediately.

    .PARAMETER CheckOnly
        Only check whether updates are available without applying them.

    .PARAMETER Force
        Skip the confirmation prompt and apply updates immediately.

    .EXAMPLE
        Update-Toolkit
    .EXAMPLE
        Update-Toolkit -CheckOnly
    .EXAMPLE
        Update-Toolkit -Force
    #>
    [CmdletBinding()]
    param(
        [switch]$CheckOnly,
        [switch]$Force
    )

    $toolkitDir = $script:ToolkitRoot

    if (-not (Test-Path (Join-Path $toolkitDir ".git"))) {
        Write-Error "Toolkit directory is not a git repository: $toolkitDir"
        return
    }

    $git = Get-Command git -ErrorAction SilentlyContinue
    if (-not $git) {
        Write-Error "Git is not installed or not in PATH."
        return
    }

    Push-Location $toolkitDir
    try {
        $currentBranch = git rev-parse --abbrev-ref HEAD 2>$null
        if (-not $currentBranch) {
            Write-Error "Failed to determine current git branch."
            return
        }

        Write-Host "Checking for updates..." -ForegroundColor Cyan
        git fetch origin $currentBranch --quiet 2>$null

        $localHead  = git rev-parse HEAD 2>$null
        $remoteHead = git rev-parse "origin/$currentBranch" 2>$null

        if ($localHead -eq $remoteHead) {
            Write-Host "Already up to date." -ForegroundColor Green
            $manifest = Import-PowerShellDataFile (Join-Path $toolkitDir "PowerShellDevToolkit\PowerShellDevToolkit.psd1")
            Write-Host "  Version: $($manifest.ModuleVersion)" -ForegroundColor Gray
            Write-Host "  Branch:  $currentBranch" -ForegroundColor Gray
            return
        }

        $behind = git rev-list --count "HEAD..origin/$currentBranch" 2>$null
        Write-Host "$behind new commit(s) available on $currentBranch" -ForegroundColor Yellow
        Write-Host ""

        $log = git log --oneline "HEAD..origin/$currentBranch" 2>$null
        if ($log) {
            Write-Host "Changes:" -ForegroundColor Cyan
            $log | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
            Write-Host ""
        }

        $diffStat = git diff --stat "HEAD..origin/$currentBranch" 2>$null
        if ($diffStat) {
            Write-Host "Files changed:" -ForegroundColor Cyan
            $diffStat | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
            Write-Host ""
        }

        if ($CheckOnly) { return }

        if (-not $Force) {
            Write-Host "Apply update? (Y/N): " -NoNewline -ForegroundColor Yellow
            $response = Read-Host
            if ($response -ne 'Y' -and $response -ne 'y') {
                Write-Host "Update cancelled." -ForegroundColor Gray
                return
            }
        }

        Write-Host "Pulling changes..." -ForegroundColor Cyan
        $pullOutput = git pull origin $currentBranch 2>&1
        $pullExitCode = $LASTEXITCODE

        if ($pullExitCode -ne 0) {
            Write-Host "Git pull failed:" -ForegroundColor Red
            $pullOutput | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
            Write-Host ""
            Write-Host "You may need to resolve conflicts manually." -ForegroundColor Yellow
            return
        }

        $pullOutput | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }

        Write-Host ""
        Write-Host "Re-importing module..." -ForegroundColor Cyan
        Import-Module (Join-Path $toolkitDir "PowerShellDevToolkit") -Force -Global -DisableNameChecking

        $manifest = Import-PowerShellDataFile (Join-Path $toolkitDir "PowerShellDevToolkit\PowerShellDevToolkit.psd1")
        Write-Host ""
        Write-Host "Updated to version $($manifest.ModuleVersion)" -ForegroundColor Green
        Write-Host "All commands and aliases are now current." -ForegroundColor Green

        Set-ToolkitUpdateTimestamp
    } finally {
        Pop-Location
    }
}

function Test-ToolkitUpdate {
    <#
    .SYNOPSIS
        Silently check if toolkit updates are available (used on shell startup).

    .DESCRIPTION
        Compares the local HEAD against the remote. Returns $true if there are
        commits to pull. Respects the updateCheckDays setting in config.json
        so it only hits the network at the configured frequency.
    #>
    [CmdletBinding()]
    param()

    $toolkitDir = $script:ToolkitRoot

    if (-not (Test-Path (Join-Path $toolkitDir ".git"))) { return }
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { return }

    $stampFile = Join-Path $toolkitDir ".last-update-check"
    $config = Get-ScriptConfig -ErrorAction SilentlyContinue
    $intervalDays = 1
    if ($config -and $config.toolkit -and $null -ne $config.toolkit.updateCheckDays) {
        $intervalDays = [int]$config.toolkit.updateCheckDays
    }

    if ($intervalDays -le 0) { return }

    if (Test-Path $stampFile) {
        $lastCheck = (Get-Item $stampFile).LastWriteTime
        if (([datetime]::Now - $lastCheck).TotalDays -lt $intervalDays) { return }
    }

    Push-Location $toolkitDir
    try {
        $branch = git rev-parse --abbrev-ref HEAD 2>$null
        if (-not $branch) { return }

        git fetch origin $branch --quiet 2>$null
        $local  = git rev-parse HEAD 2>$null
        $remote = git rev-parse "origin/$branch" 2>$null

        Set-ToolkitUpdateTimestamp

        if ($local -ne $remote) {
            $behind = git rev-list --count "HEAD..origin/$branch" 2>$null
            Write-Host ""
            Write-Host "PowerShell Dev Toolkit: $behind update(s) available. Run " -NoNewline -ForegroundColor Yellow
            Write-Host "Update-Toolkit" -NoNewline -ForegroundColor Cyan
            Write-Host " to update." -ForegroundColor Yellow
        }
    } finally {
        Pop-Location
    }
}

function Set-ToolkitUpdateTimestamp {
    <# Touches the .last-update-check stamp file. #>
    [CmdletBinding()]
    param()
    $stampFile = Join-Path $script:ToolkitRoot ".last-update-check"
    [IO.File]::WriteAllText($stampFile, (Get-Date -Format 'o'))
}
