function Update-Toolkit {
    <#
    .SYNOPSIS
        Self-update the PowerShell Dev Toolkit.

    .DESCRIPTION
        For a git-clone install, pulls the latest changes from the toolkit's git
        remote. For a PowerShell Gallery install, checks the Gallery for a newer
        version and updates with Update-Module (or Update-PSResource). In both
        cases the module is re-imported so new commands and aliases take effect
        immediately.

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

    $paths = Get-ToolkitPaths

    if ($paths.InstallType -eq 'Gallery') {
        Update-ToolkitFromGallery -Paths $paths -CheckOnly:$CheckOnly -Force:$Force
    }
    else {
        Update-ToolkitFromGit -Paths $paths -CheckOnly:$CheckOnly -Force:$Force
    }
}

function Update-ToolkitFromGit {
    <# Git-clone update flow (private). #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] $Paths,
        [switch]$CheckOnly,
        [switch]$Force
    )

    $toolkitDir = $Paths.RepoRoot

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
            $manifest = Import-PowerShellDataFile (Join-Path $Paths.ModuleRoot "PowerShellDevToolkit.psd1")
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
        Import-Module $Paths.ModuleRoot -Force -Global -DisableNameChecking

        $manifest = Import-PowerShellDataFile (Join-Path $Paths.ModuleRoot "PowerShellDevToolkit.psd1")
        Write-Host ""
        Write-Host "Updated to version $($manifest.ModuleVersion)" -ForegroundColor Green
        Write-Host "All commands and aliases are now current." -ForegroundColor Green

        Set-ToolkitUpdateTimestamp
    } finally {
        Pop-Location
    }
}

function Update-ToolkitFromGallery {
    <# PowerShell Gallery update flow (private). #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] $Paths,
        [switch]$CheckOnly,
        [switch]$Force
    )

    Write-Host "Checking the PowerShell Gallery for updates..." -ForegroundColor Cyan
    $status = Get-ToolkitGalleryStatus -Paths $Paths
    if (-not $status) {
        Write-Host "Could not reach the PowerShell Gallery. Check your network connection and try again." -ForegroundColor Red
        return
    }

    if (-not $status.UpdateAvailable) {
        Write-Host "Already up to date." -ForegroundColor Green
        Write-Host "  Version: $($status.Installed)" -ForegroundColor Gray
        Write-Host "  Source:  PowerShell Gallery" -ForegroundColor Gray
        Set-ToolkitUpdateTimestamp
        return
    }

    Write-Host "Update available: $($status.Installed) -> $($status.Latest)" -ForegroundColor Yellow
    if ($status.ReleaseNotes) {
        Write-Host ""
        Write-Host "Release notes:" -ForegroundColor Cyan
        ($status.ReleaseNotes -split "`r?`n") | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    }
    Write-Host ""

    if ($CheckOnly) { return }

    if (-not $Force) {
        Write-Host "Apply update? (Y/N): " -NoNewline -ForegroundColor Yellow
        $response = Read-Host
        if ($response -ne 'Y' -and $response -ne 'y') {
            Write-Host "Update cancelled." -ForegroundColor Gray
            return
        }
    }

    Write-Host "Updating from the PowerShell Gallery..." -ForegroundColor Cyan
    try {
        if (Get-InstalledModule -Name PowerShellDevToolkit -ErrorAction SilentlyContinue) {
            Update-Module -Name PowerShellDevToolkit -Force -ErrorAction Stop
        }
        elseif ((Get-Command Update-PSResource -ErrorAction SilentlyContinue) -and
                (Get-InstalledPSResource -Name PowerShellDevToolkit -ErrorAction SilentlyContinue)) {
            Update-PSResource -Name PowerShellDevToolkit -ErrorAction Stop
        }
        else {
            Write-Host "Could not determine how the module was installed." -ForegroundColor Red
            Write-Host "Update manually with: Update-Module PowerShellDevToolkit   (or: Update-PSResource PowerShellDevToolkit)" -ForegroundColor Yellow
            return
        }
    }
    catch {
        Write-Host "Update failed: $($_.Exception.Message)" -ForegroundColor Red
        return
    }

    Write-Host ""
    Write-Host "Re-importing module..." -ForegroundColor Cyan
    Import-Module PowerShellDevToolkit -Force -Global -DisableNameChecking

    $newVersion = (Get-Module PowerShellDevToolkit).Version
    Write-Host ""
    Write-Host "Updated to version $newVersion" -ForegroundColor Green
    Write-Host "All commands and aliases are now current." -ForegroundColor Green

    Set-ToolkitUpdateTimestamp
}

function Test-ToolkitUpdate {
    <#
    .SYNOPSIS
        Silently check if toolkit updates are available (used on shell startup).

    .DESCRIPTION
        Compares the local install against its source (git remote or the
        PowerShell Gallery). Respects the updateCheckDays setting in config.json
        so it only hits the network at the configured frequency. Set
        $env:PSDT_SKIP_UPDATE_CHECK to skip the startup check entirely.
    #>
    [CmdletBinding()]
    param()

    $paths = Get-ToolkitPaths

    if ($paths.InstallType -eq 'Git' -and -not (Get-Command git -ErrorAction SilentlyContinue)) { return }

    $config = Get-ScriptConfig -Quiet
    $intervalDays = 1
    if ($config -and $config.toolkit -and $null -ne $config.toolkit.updateCheckDays) {
        $intervalDays = [int]$config.toolkit.updateCheckDays
    }

    if ($intervalDays -le 0) { return }

    if (Test-Path $paths.UpdateStampPath) {
        $lastCheck = (Get-Item $paths.UpdateStampPath).LastWriteTime
        if (([datetime]::Now - $lastCheck).TotalDays -lt $intervalDays) { return }
    }

    if ($paths.InstallType -eq 'Gallery') {
        $status = Get-ToolkitGalleryStatus -Paths $paths
        Set-ToolkitUpdateTimestamp
        if ($status -and $status.UpdateAvailable) {
            Write-ToolkitUpdateHint "version $($status.Latest) is"
        }
        return
    }

    Push-Location $paths.RepoRoot
    try {
        $branch = git rev-parse --abbrev-ref HEAD 2>$null
        if (-not $branch) { return }

        git fetch origin $branch --quiet 2>$null
        $local  = git rev-parse HEAD 2>$null
        $remote = git rev-parse "origin/$branch" 2>$null

        Set-ToolkitUpdateTimestamp

        if ($local -ne $remote) {
            $behind = git rev-list --count "HEAD..origin/$branch" 2>$null
            Write-ToolkitUpdateHint "$behind update(s)"
        }
    } finally {
        Pop-Location
    }
}

function Write-ToolkitUpdateHint {
    <# Prints the one-line "update available" hint (private). #>
    [CmdletBinding()]
    param([string]$What)

    Write-Host ""
    Write-Host "PowerShell Dev Toolkit: $What available. Run " -NoNewline -ForegroundColor Yellow
    Write-Host "Update-Toolkit" -NoNewline -ForegroundColor Cyan
    Write-Host " to update." -ForegroundColor Yellow
}

function Set-ToolkitUpdateTimestamp {
    <# Touches the .last-update-check stamp file (private). #>
    [CmdletBinding()]
    param()

    $stampFile = (Get-ToolkitPaths).UpdateStampPath
    $stampDir  = Split-Path $stampFile -Parent
    if (-not (Test-Path $stampDir)) {
        New-Item -Path $stampDir -ItemType Directory -Force | Out-Null
    }
    [IO.File]::WriteAllText($stampFile, (Get-Date -Format 'o'))
}
