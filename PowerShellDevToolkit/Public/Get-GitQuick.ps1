function Get-GitQuick {
    <#
    .SYNOPSIS
        Enhanced git status with branch info.

    .DESCRIPTION
        Shows a quick, colorized git status with current branch,
        ahead/behind remote, modified/staged/untracked files, and stash count.

    .PARAMETER AsJson
        Output as JSON for MCP tools.

    .EXAMPLE
        Get-GitQuick
        gs -AsJson
    #>
    [CmdletBinding()]
    param(
        [switch]$AsJson
    )

    $isGitRepo = git rev-parse --is-inside-work-tree 2>$null
    if ($isGitRepo -ne 'true') {
        if ($AsJson) {
            @{ error = 'Not a git repository' } | ConvertTo-Json
        } else {
            Write-Host "Not a git repository" -ForegroundColor Red
        }
        return
    }

    $branch = git branch --show-current 2>$null
    $status = git status --porcelain 2>$null
    $stashCount = (git stash list 2>$null | Measure-Object).Count

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

        if ($index -eq 'U' -or $worktree -eq 'U') {
            $conflicts += $file
            continue
        }

        if ($index -match '[MADRC]') {
            $staged += $file
        }

        if ($worktree -eq 'M') {
            $modified += $file
        } elseif ($worktree -eq 'D') {
            $deleted += $file
        } elseif ($index -eq '?' -and $worktree -eq '?') {
            $untracked += $file
        }
    }

    $remote = git remote get-url origin 2>$null
    if ($remote) {
        $remote = $remote -replace '\.git$', '' -replace '^git@github\.com:', 'github.com/' -replace '^https?://', ''
    }

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
        return
    }

    Write-Host ""
    Write-Host "  Branch: " -NoNewline -ForegroundColor Gray
    Write-Host $branch -NoNewline -ForegroundColor Cyan

    if ($ahead -gt 0 -or $behind -gt 0) {
        Write-Host " [" -NoNewline -ForegroundColor DarkGray
        if ($ahead -gt 0) {
            Write-Host "$([char]0x2191)$ahead" -NoNewline -ForegroundColor Green
        }
        if ($behind -gt 0) {
            if ($ahead -gt 0) { Write-Host " " -NoNewline }
            Write-Host "$([char]0x2193)$behind" -NoNewline -ForegroundColor Red
        }
        Write-Host "]" -NoNewline -ForegroundColor DarkGray
    }
    Write-Host ""

    if ($remote) {
        Write-Host "  Remote: " -NoNewline -ForegroundColor Gray
        Write-Host $remote -ForegroundColor DarkGray
    }

    Write-Host ""

    $isClean = $status.Count -eq 0

    if ($isClean) {
        Write-Host "  [OK] Working tree clean" -ForegroundColor Green
    } else {
        if ($conflicts.Count -gt 0) {
            Write-Host "  [CONFLICT] $($conflicts.Count) conflict(s)" -ForegroundColor Red
            $conflicts | Select-Object -First 3 | ForEach-Object {
                Write-Host "    ! $_" -ForegroundColor Red
            }
        }

        if ($staged.Count -gt 0) {
            Write-Host "  $([char]0x25CF) $($staged.Count) staged" -ForegroundColor Green
            $staged | Select-Object -First 3 | ForEach-Object {
                Write-Host "    + $_" -ForegroundColor Green
            }
            if ($staged.Count -gt 3) {
                Write-Host "    ... and $($staged.Count - 3) more" -ForegroundColor DarkGray
            }
        }

        if ($modified.Count -gt 0) {
            Write-Host "  $([char]0x25CB) $($modified.Count) modified" -ForegroundColor Yellow
            $modified | Select-Object -First 3 | ForEach-Object {
                Write-Host "    ~ $_" -ForegroundColor Yellow
            }
            if ($modified.Count -gt 3) {
                Write-Host "    ... and $($modified.Count - 3) more" -ForegroundColor DarkGray
            }
        }

        if ($deleted.Count -gt 0) {
            Write-Host "  [DEL] $($deleted.Count) deleted" -ForegroundColor Red
            $deleted | Select-Object -First 3 | ForEach-Object {
                Write-Host "    - $_" -ForegroundColor Red
            }
        }

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

    if ($stashCount -gt 0) {
        Write-Host ""
        Write-Host "  [STASH] $stashCount stashes" -ForegroundColor Magenta
    }

    Write-Host ""
}
