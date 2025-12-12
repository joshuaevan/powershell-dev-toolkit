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

.PARAMETER Follow
    Keep watching for new lines (default behavior). Use -NoFollow to disable.

.PARAMETER NoFollow
    Don't follow the file, just show the last lines.

.PARAMETER FilterOnly
    Only show lines matching the filter (instead of highlighting).

.EXAMPLE
    tail .\app.log
    tail .\app.log -Filter "error"
    tail .\storage\logs\laravel.log -Last 50
    tail .\app.log -Filter "error" -FilterOnly
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

# Resolve path
$resolvedPath = Resolve-Path $Path -ErrorAction SilentlyContinue
if (-not $resolvedPath) {
    Write-Host "File not found: $Path" -ForegroundColor Red
    exit 1
}
$Path = $resolvedPath.Path

# Helper to colorize log lines
function Write-LogLine {
    param(
        [string]$Line,
        [string]$Pattern
    )
    
    # Skip if FilterOnly and no match
    if ($FilterOnly -and $Pattern -and $Line -notmatch $Pattern) {
        return
    }
    
    # Determine color based on content
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
    
    # Highlight filter matches
    if ($Pattern -and $Line -match $Pattern) {
        # Split and highlight
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

# Show header
Write-Host ""
Write-Host "Tailing: " -NoNewline -ForegroundColor Cyan
Write-Host $Path -ForegroundColor Yellow
if ($Filter) {
    Write-Host "Filter:  " -NoNewline -ForegroundColor Cyan
    Write-Host $Filter -ForegroundColor Yellow
}
Write-Host ("-" * 60) -ForegroundColor DarkGray
Write-Host ""

# Get initial content
$lines = Get-Content $Path -Tail $Last -ErrorAction SilentlyContinue

foreach ($line in $lines) {
    Write-LogLine -Line $line -Pattern $Filter
}

# Follow mode
if (-not $NoFollow) {
    Write-Host ""
    Write-Host "--- Watching for changes (Ctrl+C to stop) ---" -ForegroundColor DarkGray
    Write-Host ""
    
    try {
        Get-Content $Path -Wait -Tail 0 | ForEach-Object {
            Write-LogLine -Line $_ -Pattern $Filter
        }
    } catch {
        # User pressed Ctrl+C
        Write-Host ""
        Write-Host "Stopped watching." -ForegroundColor Gray
    }
}
