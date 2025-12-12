<#
.SYNOPSIS
    Enhanced git status with branch info.

.DESCRIPTION
    Shows a quick, colorized git status with:
    - Current branch
    - Ahead/behind remote
    - Modified/staged/untracked files
    - Stash count

.PARAMETER AsJson
    Output as JSON for MCP tools.

.EXAMPLE
    gs
    gs -AsJson
#>

[CmdletBinding()]
param(
    [switch]$AsJson
)

# Check if in git repo
if (-not (Test-Path '.git')) {
    if ($AsJson) {
        @{ error = 'Not a git repository' } | ConvertTo-Json
    } else {
        Write-Host "Not a git repository" -ForegroundColor Red
    }
    exit 1
}

# Gather git info
$branch = git branch --show-current 2>$null
$status = git status --porcelain 2>$null
$stashCount = (git stash list 2>$null | Measure-Object).Count

# Get ahead/behind
$ahead = 0
$behind = 0
$tracking = git rev-parse --abbrev-ref '@{upstream}' 2>$null
if ($tracking) {
    $counts = git rev-list --left-right --count "HEAD...$tracking" 2>$null
    if ($counts -match '(\d+)\s+(\d+)') {
        $ahead = [int]$Matches[1]
        $behind = [int]$Matches[2]
    }
}

# Parse status
$staged = @()
$modified = @()
$untracked = @()
$deleted = @()
$conflicts = @()

foreach ($line in $status) {
    if ($line.Length -lt 3) { continue }
    
    $index = $line[0]
    $worktree = $line[1]
    $file = $line.Substring(3)
    
    # Conflicts
    if ($index -eq 'U' -or $worktree -eq 'U') {
        $conflicts += $file
        continue
    }
    
    # Staged changes
    if ($index -match '[MADRC]') {
        $staged += $file
    }
    
    # Working tree changes
    if ($worktree -eq 'M') {
        $modified += $file
    } elseif ($worktree -eq 'D') {
        $deleted += $file
    } elseif ($index -eq '?' -and $worktree -eq '?') {
        $untracked += $file
    }
}

# Get remote URL
$remote = git remote get-url origin 2>$null
if ($remote) {
    # Simplify GitHub/GitLab URLs
    $remote = $remote -replace '\.git$', '' -replace '^git@github\.com:', 'github.com/' -replace '^https?://', ''
}

# JSON output
if ($AsJson) {
    $result = [ordered]@{
        branch = $branch
        remote = $remote
        tracking = $tracking
        ahead = $ahead
        behind = $behind
        staged = $staged.Count
        modified = $modified.Count
        deleted = $deleted.Count
        untracked = $untracked.Count
        conflicts = $conflicts.Count
        stashes = $stashCount
        clean = ($status.Count -eq 0)
        files = [ordered]@{
            staged = $staged
            modified = $modified
            deleted = $deleted
            untracked = $untracked
            conflicts = $conflicts
        }
    }
    $result | ConvertTo-Json -Depth 5
    exit 0
}

# Pretty output
Write-Host ""

# Branch with status
Write-Host "  Branch: " -NoNewline -ForegroundColor Gray
Write-Host $branch -NoNewline -ForegroundColor Cyan

# Ahead/behind
if ($ahead -gt 0 -or $behind -gt 0) {
    Write-Host " [" -NoNewline -ForegroundColor DarkGray
    if ($ahead -gt 0) {
        Write-Host "↑$ahead" -NoNewline -ForegroundColor Green
    }
    if ($behind -gt 0) {
        if ($ahead -gt 0) { Write-Host " " -NoNewline }
        Write-Host "↓$behind" -NoNewline -ForegroundColor Red
    }
    Write-Host "]" -NoNewline -ForegroundColor DarkGray
}
Write-Host ""

# Remote
if ($remote) {
    Write-Host "  Remote: " -NoNewline -ForegroundColor Gray
    Write-Host $remote -ForegroundColor DarkGray
}

Write-Host ""

# Status summary
$isClean = $status.Count -eq 0

if ($isClean) {
    Write-Host "  [OK] Working tree clean" -ForegroundColor Green
} else {
    # Conflicts (highest priority)
    if ($conflicts.Count -gt 0) {
        Write-Host "  [CONFLICT] $($conflicts.Count) conflict(s)" -ForegroundColor Red
        $conflicts | Select-Object -First 3 | ForEach-Object {
            Write-Host "    ! $_" -ForegroundColor Red
        }
    }
    
    # Staged
    if ($staged.Count -gt 0) {
        Write-Host "  ● $($staged.Count) staged" -ForegroundColor Green
        $staged | Select-Object -First 3 | ForEach-Object {
            Write-Host "    + $_" -ForegroundColor Green
        }
        if ($staged.Count -gt 3) {
            Write-Host "    ... and $($staged.Count - 3) more" -ForegroundColor DarkGray
        }
    }
    
    # Modified
    if ($modified.Count -gt 0) {
        Write-Host "  ○ $($modified.Count) modified" -ForegroundColor Yellow
        $modified | Select-Object -First 3 | ForEach-Object {
            Write-Host "    ~ $_" -ForegroundColor Yellow
        }
        if ($modified.Count -gt 3) {
            Write-Host "    ... and $($modified.Count - 3) more" -ForegroundColor DarkGray
        }
    }
    
    # Deleted
    if ($deleted.Count -gt 0) {
        Write-Host "  [DEL] $($deleted.Count) deleted" -ForegroundColor Red
        $deleted | Select-Object -First 3 | ForEach-Object {
            Write-Host "    - $_" -ForegroundColor Red
        }
    }
    
    # Untracked
    if ($untracked.Count -gt 0) {
        Write-Host "  ? $($untracked.Count) untracked" -ForegroundColor DarkGray
        $untracked | Select-Object -First 3 | ForEach-Object {
            Write-Host "    ? $_" -ForegroundColor DarkGray
        }
        if ($untracked.Count -gt 3) {
            Write-Host "    ... and $($untracked.Count - 3) more" -ForegroundColor DarkGray
        }
    }
}

# Stashes
if ($stashCount -gt 0) {
    Write-Host ""
    Write-Host "  [STASH] $stashCount stash(es)" -ForegroundColor Magenta
}

Write-Host ""
