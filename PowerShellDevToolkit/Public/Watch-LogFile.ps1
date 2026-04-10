function Watch-LogFile {
    <#
    .SYNOPSIS
        Tail log files with optional filtering.

    .DESCRIPTION
        Watch a log file in real-time, similar to Unix 'tail -f'.
        Supports filtering by pattern and showing last N lines.

    .PARAMETER Path
        Path to the log file.

    .PARAMETER Filter
        Filter pattern (regex) to highlight or filter lines.

    .PARAMETER Last
        Show only the last N lines initially.

    .PARAMETER NoFollow
        Don't follow the file, just show the last lines.

    .PARAMETER FilterOnly
        Only show lines matching the filter.

    .EXAMPLE
        Watch-LogFile .\app.log
        tail .\app.log -Filter "error"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$Path,

        [Parameter(Position = 1)]
        [string]$Filter,

        [int]$Last = 20,

        [switch]$NoFollow,
        [switch]$FilterOnly
    )

    $resolvedPath = Resolve-Path $Path -ErrorAction SilentlyContinue
    if (-not $resolvedPath) {
        Write-Host "File not found: $Path" -ForegroundColor Red
        return
    }
    $Path = $resolvedPath.Path

    function Write-LogLine {
        param(
            [string]$Line,
            [string]$Pattern
        )

        if ($FilterOnly -and $Pattern -and $Line -notmatch $Pattern) {
            return
        }

        $color = 'White'
        if ($Line -match '\b(ERROR|FATAL|CRITICAL|EXCEPTION)\b') {
            $color = 'Red'
        } elseif ($Line -match '\b(WARN|WARNING)\b') {
            $color = 'Yellow'
        } elseif ($Line -match '\b(INFO)\b') {
            $color = 'Cyan'
        } elseif ($Line -match '\b(DEBUG|TRACE)\b') {
            $color = 'DarkGray'
        } elseif ($Line -match '\b(SUCCESS|OK)\b') {
            $color = 'Green'
        }

        if ($Pattern -and $Line -match $Pattern) {
            $parts = $Line -split "($Pattern)"
            foreach ($part in $parts) {
                if ($part -match $Pattern) {
                    Write-Host $part -NoNewline -ForegroundColor Black -BackgroundColor Yellow
                } else {
                    Write-Host $part -NoNewline -ForegroundColor $color
                }
            }
            Write-Host ""
        } else {
            Write-Host $Line -ForegroundColor $color
        }
    }

    Write-Host ""
    Write-Host "Tailing: " -NoNewline -ForegroundColor Cyan
    Write-Host $Path -ForegroundColor Yellow
    if ($Filter) {
        Write-Host "Filter:  " -NoNewline -ForegroundColor Cyan
        Write-Host $Filter -ForegroundColor Yellow
    }
    Write-Host ("-" * 60) -ForegroundColor DarkGray
    Write-Host ""

    $lines = Get-Content $Path -Tail $Last -ErrorAction SilentlyContinue

    foreach ($line in $lines) {
        Write-LogLine -Line $line -Pattern $Filter
    }

    if (-not $NoFollow) {
        Write-Host ""
        Write-Host "--- Watching for changes (Ctrl+C to stop) ---" -ForegroundColor DarkGray
        Write-Host ""

        try {
            Get-Content $Path -Wait -Tail 0 | ForEach-Object {
                Write-LogLine -Line $_ -Pattern $Filter
            }
        } catch {
            Write-Host ""
            Write-Host "Stopped watching." -ForegroundColor Gray
        }
    }
}
