<#
.SYNOPSIS
    Search across project files (respects common ignore patterns).

.DESCRIPTION
    Searches for patterns in project files, automatically excluding
    node_modules, vendor, .git, and other common directories.

.PARAMETER Pattern
    The search pattern (regex supported).

.PARAMETER Type
    File type filter: php, js, ts, css, html, json, perl, py, etc.
    Can specify multiple types separated by comma.

.PARAMETER Path
    Directory to search in (defaults to current directory).

.PARAMETER CaseSensitive
    Make search case-sensitive.

.PARAMETER AsJson
    Output as JSON for MCP tools.

.PARAMETER Context
    Number of context lines to show around matches.

.EXAMPLE
    search "function login"           # Search all files
    search "TODO" -Type php           # Only PHP files
    search "import" -Type js,ts       # JS/TS files
    search "pattern" -AsJson          # JSON output for AI
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory = $true)]
    [string]$Pattern,

    [Parameter(Position = 1)]
    [string]$Type,

    [string]$Path = '.',

    [switch]$CaseSensitive,
    [switch]$AsJson,

    [int]$Context = 0
)

# Resolve path
$searchPath = Resolve-Path $Path -ErrorAction SilentlyContinue
if (-not $searchPath) {
    Write-Host "Path not found: $Path" -ForegroundColor Red
    exit 1
}

# Directories to exclude
$excludeDirs = @(
    'node_modules', 'vendor', '.git', '__pycache__', '.idea', '.vscode',
    'venv', '.venv', 'dist', 'build', 'coverage', '.next', '.nuxt',
    'storage/framework', 'bootstrap/cache', 'target', 'bin', 'obj'
)

# File extensions by type
$typeExtensions = @{
    'php' = @('*.php')
    'js' = @('*.js', '*.jsx', '*.mjs')
    'ts' = @('*.ts', '*.tsx')
    'css' = @('*.css', '*.scss', '*.sass', '*.less')
    'html' = @('*.html', '*.htm', '*.blade.php', '*.twig')
    'json' = @('*.json')
    'perl' = @('*.pl', '*.pm', '*.t')
    'py' = @('*.py')
    'python' = @('*.py')
    'md' = @('*.md', '*.markdown')
    'sql' = @('*.sql')
    'yaml' = @('*.yaml', '*.yml')
    'xml' = @('*.xml')
    'config' = @('*.json', '*.yaml', '*.yml', '*.xml', '*.ini', '*.env*')
}

# Build include patterns
$includePatterns = @()
if ($Type) {
    $types = $Type.ToLower() -split '[,\s]+'
    foreach ($t in $types) {
        if ($typeExtensions.ContainsKey($t)) {
            $includePatterns += $typeExtensions[$t]
        } else {
            $includePatterns += "*.$t"
        }
    }
}

# Get files to search
$files = Get-ChildItem -Path $searchPath -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
    $filePath = $_.FullName
    
    # Exclude directories
    foreach ($excludeDir in $excludeDirs) {
        if ($filePath -match "[\\/]$excludeDir[\\/]") {
            return $false
        }
    }
    
    # Include by type if specified
    if ($includePatterns.Count -gt 0) {
        $matched = $false
        foreach ($pattern in $includePatterns) {
            if ($_.Name -like $pattern) {
                $matched = $true
                break
            }
        }
        return $matched
    }
    
    # Exclude binary/large files
    $excludeExtensions = @('.exe', '.dll', '.zip', '.tar', '.gz', '.png', '.jpg', '.gif', '.ico', '.woff', '.woff2', '.ttf', '.eot', '.mp3', '.mp4', '.pdf')
    if ($excludeExtensions -contains $_.Extension.ToLower()) {
        return $false
    }
    
    return $true
}

# Search in files
$results = @()
$totalMatches = 0

foreach ($file in $files) {
    try {
        $content = Get-Content $file.FullName -ErrorAction Stop
        $lineNum = 0
        $fileMatches = @()
        
        foreach ($line in $content) {
            $lineNum++
            
            $isMatch = if ($CaseSensitive) {
                $line -cmatch $Pattern
            } else {
                $line -match $Pattern
            }
            
            if ($isMatch) {
                $fileMatches += [ordered]@{
                    line = $lineNum
                    content = $line.Trim()
                }
                $totalMatches++
            }
        }
        
        if ($fileMatches.Count -gt 0) {
            $relativePath = $file.FullName.Replace($searchPath.Path, '').TrimStart('\', '/')
            $results += [ordered]@{
                file = $relativePath
                matches = $fileMatches
                count = $fileMatches.Count
            }
        }
    } catch {
        # Skip files that can't be read
    }
}

# JSON output
if ($AsJson) {
    @{
        pattern = $Pattern
        totalMatches = $totalMatches
        fileCount = $results.Count
        results = $results
    } | ConvertTo-Json -Depth 10
    exit 0
}

# Pretty output
Write-Host ""
Write-Host "Search: " -NoNewline -ForegroundColor Cyan
Write-Host $Pattern -ForegroundColor Yellow
if ($Type) {
    Write-Host "Type:   " -NoNewline -ForegroundColor Cyan
    Write-Host $Type -ForegroundColor Yellow
}
Write-Host ""

if ($results.Count -eq 0) {
    Write-Host "No matches found." -ForegroundColor DarkGray
    Write-Host ""
    exit 0
}

foreach ($result in $results) {
    Write-Host $result.file -ForegroundColor Green
    
    foreach ($match in $result.matches | Select-Object -First 5) {
        Write-Host "  " -NoNewline
        Write-Host "$($match.line.ToString().PadLeft(4)):" -NoNewline -ForegroundColor DarkGray
        
        # Highlight match in line
        $line = $match.content
        if ($line -match "($Pattern)") {
            $parts = $line -split "($Pattern)"
            foreach ($part in $parts) {
                if ($part -match "^$Pattern$") {
                    Write-Host $part -NoNewline -ForegroundColor Black -BackgroundColor Yellow
                } else {
                    Write-Host $part -NoNewline -ForegroundColor White
                }
            }
            Write-Host ""
        } else {
            Write-Host " $line" -ForegroundColor White
        }
    }
    
    if ($result.matches.Count -gt 5) {
        Write-Host "  ... $($result.matches.Count - 5) more matches" -ForegroundColor DarkGray
    }
    Write-Host ""
}

Write-Host "Found " -NoNewline -ForegroundColor Cyan
Write-Host $totalMatches -NoNewline -ForegroundColor Yellow
Write-Host " matches in " -NoNewline -ForegroundColor Cyan
Write-Host $results.Count -NoNewline -ForegroundColor Yellow
Write-Host " files" -ForegroundColor Cyan
Write-Host ""
