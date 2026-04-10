<#
.SYNOPSIS
    Copy file contents or paths to clipboard.

.DESCRIPTION
    Copies file contents, file paths, or current directory to clipboard.
    Useful for quickly sharing code snippets or paths.

.PARAMETER Path
    Path to file to copy contents from.

.PARAMETER PathOnly
    Copy the full path instead of contents.

.PARAMETER Pwd
    Copy current working directory.

.PARAMETER Relative
    Use relative path instead of absolute (with -PathOnly).

.EXAMPLE
    clip .\config.json         # Copy file contents
    clip .\config.json -Path   # Copy full path
    clip -Pwd                  # Copy current directory
#>

[CmdletBinding(DefaultParameterSetName = 'Content')]
param(
    [Parameter(Position = 0, ParameterSetName = 'Content')]
    [Parameter(Position = 0, ParameterSetName = 'PathOnly')]
    [string]$Path,

    [Parameter(ParameterSetName = 'PathOnly')]
    [Alias('PathMode')]
    [switch]$PathOnly,

    [Parameter(ParameterSetName = 'Pwd')]
    [switch]$Pwd,

    [switch]$Relative
)

# Copy current directory
if ($Pwd) {
    $dir = (Get-Location).Path
    $dir | Set-Clipboard
    Write-Host ""
    Write-Host "Copied to clipboard: " -NoNewline -ForegroundColor Green
    Write-Host $dir -ForegroundColor Yellow
    Write-Host ""
    exit 0
}

# Require path for other operations
if (-not $Path) {
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Cyan
    Write-Host "  clip <file>        # Copy file contents"
    Write-Host "  clip <file> -Path  # Copy file path"
    Write-Host "  clip -Pwd          # Copy current directory"
    Write-Host ""
    exit 1
}

# Resolve path
$resolvedPath = Resolve-Path $Path -ErrorAction SilentlyContinue
if (-not $resolvedPath) {
    Write-Host ""
    Write-Host "File not found: $Path" -ForegroundColor Red
    Write-Host ""
    exit 1
}
$fullPath = $resolvedPath.Path

# Copy path only
if ($PathOnly) {
    $output = if ($Relative) { $Path } else { $fullPath }
    $output | Set-Clipboard
    Write-Host ""
    Write-Host "Copied path: " -NoNewline -ForegroundColor Green
    Write-Host $output -ForegroundColor Yellow
    Write-Host ""
    exit 0
}

# Check if it's a directory
if (Test-Path $fullPath -PathType Container) {
    $fullPath | Set-Clipboard
    Write-Host ""
    Write-Host "Copied directory path: " -NoNewline -ForegroundColor Green
    Write-Host $fullPath -ForegroundColor Yellow
    Write-Host ""
    exit 0
}

# Copy file contents
try {
    $content = Get-Content $fullPath -Raw -ErrorAction Stop
    $content | Set-Clipboard
    
    $lines = ($content -split "`n").Count
    $chars = $content.Length
    
    Write-Host ""
    Write-Host "Copied contents of " -NoNewline -ForegroundColor Green
    Write-Host (Split-Path $fullPath -Leaf) -NoNewline -ForegroundColor Yellow
    Write-Host " ($lines lines, $chars chars)" -ForegroundColor Green
    Write-Host ""
    
    # Show preview for small files
    if ($lines -le 10) {
        Write-Host "Preview:" -ForegroundColor Cyan
        Write-Host ("-" * 40) -ForegroundColor DarkGray
        Write-Host $content -ForegroundColor White
        Write-Host ("-" * 40) -ForegroundColor DarkGray
        Write-Host ""
    }
    
} catch {
    Write-Host ""
    Write-Host "Error reading file: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    exit 1
}
