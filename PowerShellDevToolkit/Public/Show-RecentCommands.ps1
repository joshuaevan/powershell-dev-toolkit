function Show-RecentCommands {
    <#
    .SYNOPSIS
        Display recent unique PowerShell commands in a paginated, readable format.

    .PARAMETER Count
        Maximum number of unique commands to retrieve (default: 500).

    .PARAMETER PageSize
        Number of commands to display per page (default: 30).

    .PARAMETER Page
        Page number to display (default: 1).

    .PARAMETER Interactive
        Enable interactive pagination mode.

    .EXAMPLE
        Show-RecentCommands
        rc -Interactive
        rc -Page 2
    #>
    [CmdletBinding()]
    param(
        [int]$Count = 500,
        [int]$PageSize = 30,
        [int]$Page = 1,
        [switch]$Interactive
    )

    function Show-CommandsPage {
        param(
            [System.Collections.Generic.List[string]]$Commands,
            [int]$CurrentPage,
            [int]$PageSize
        )

        $totalPages = [Math]::Ceiling($Commands.Count / $PageSize)
        $startIndex = ($CurrentPage - 1) * $PageSize
        $endIndex = [Math]::Min($startIndex + $PageSize - 1, $Commands.Count - 1)

        if ($startIndex -ge $Commands.Count) {
            Write-Host "`nNo commands to display on page $CurrentPage." -ForegroundColor Yellow
            return $false
        }

        Write-Host "`n" -NoNewline
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "  Recent Commands (Page $CurrentPage of $totalPages)" -ForegroundColor Cyan
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "  Showing commands $($startIndex + 1) - $($endIndex + 1) of $($Commands.Count)" -ForegroundColor Gray
        Write-Host ""

        for ($i = $startIndex; $i -le $endIndex; $i++) {
            $cmdNum = $i + 1
            $command = $Commands[$i]

            Write-Host "  " -NoNewline
            Write-Host "[$($cmdNum.ToString().PadLeft($Commands.Count.ToString().Length))]" -ForegroundColor DarkGray -NoNewline
            Write-Host " " -NoNewline
            Write-Host $command -ForegroundColor White
        }

        Write-Host ""
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host ""

        return $true
    }

    try {
        $histPath = (Get-PSReadLineOption).HistorySavePath
        if (-not (Test-Path $histPath)) {
            Write-Host "History file not found at: $histPath" -ForegroundColor Red
            return
        }
    } catch {
        Write-Host "Error accessing PSReadLine history: $_" -ForegroundColor Red
        return
    }

    $lines = Get-Content $histPath
    $seen = [System.Collections.Generic.HashSet[string]]::new()
    $unique = New-Object System.Collections.Generic.List[string]

    for ($i = $lines.Count - 1; $i -ge 0; $i--) {
        $line = $lines[$i].Trim()
        if ($line -and $seen.Add($line)) {
            $unique.Add($line)
            if ($unique.Count -ge $Count) { break }
        }
    }

    [Array]::Reverse($unique)

    if ($unique.Count -eq 0) {
        Write-Host "No commands found in history." -ForegroundColor Yellow
        return
    }

    if ($Interactive) {
        $currentPage = 1
        $totalPages = [Math]::Ceiling($unique.Count / $PageSize)

        while ($true) {
            Clear-Host
            if (-not (Show-CommandsPage -Commands $unique -CurrentPage $currentPage -PageSize $PageSize)) {
                $currentPage = 1
                continue
            }

            Write-Host "Navigation: " -NoNewline -ForegroundColor Yellow
            Write-Host "[N]ext " -NoNewline -ForegroundColor Cyan
            Write-Host "[P]revious " -NoNewline -ForegroundColor Cyan
            Write-Host "[G]oto page " -NoNewline -ForegroundColor Cyan
            Write-Host "[Q]uit" -ForegroundColor Cyan
            Write-Host ""

            $userInput = Read-Host "Enter command"

            switch ($userInput.ToLower()) {
                'n' {
                    if ($currentPage -lt $totalPages) {
                        $currentPage++
                    } else {
                        Write-Host "Already on last page." -ForegroundColor Yellow
                        Start-Sleep -Seconds 1
                    }
                }
                'p' {
                    if ($currentPage -gt 1) {
                        $currentPage--
                    } else {
                        Write-Host "Already on first page." -ForegroundColor Yellow
                        Start-Sleep -Seconds 1
                    }
                }
                'g' {
                    $pageInput = Read-Host "Enter page number (1-$totalPages)"
                    if ([int]::TryParse($pageInput, [ref]$null)) {
                        $pageNum = [int]$pageInput
                        if ($pageNum -ge 1 -and $pageNum -le $totalPages) {
                            $currentPage = $pageNum
                        } else {
                            Write-Host "Invalid page number. Must be between 1 and $totalPages." -ForegroundColor Red
                            Start-Sleep -Seconds 2
                        }
                    } else {
                        Write-Host "Invalid input. Please enter a number." -ForegroundColor Red
                        Start-Sleep -Seconds 2
                    }
                }
                'q' {
                    Clear-Host
                    return
                }
                default {
                    Write-Host "Invalid command. Use N, P, G, or Q." -ForegroundColor Red
                    Start-Sleep -Seconds 1
                }
            }
        }
    } else {
        Show-CommandsPage -Commands $unique -CurrentPage $Page -PageSize $PageSize | Out-Null
    }
}
