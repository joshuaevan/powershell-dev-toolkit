<#
.SYNOPSIS
    Generate a comprehensive project summary for AI tools.

.DESCRIPTION
    Creates a context summary of the current project including:
    - Project type detection
    - Key files and structure
    - Dependencies
    - Git status
    - Available scripts/commands

.PARAMETER Path
    Path to project directory (defaults to current directory).

.PARAMETER Brief
    Output a short summary only.

.PARAMETER AsJson
    Output as JSON for MCP tools.

.PARAMETER Copy
    Copy output to clipboard.

.EXAMPLE
    context
    context -Brief
    context -AsJson
    context -Copy
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Path = '.',

    [switch]$Brief,
    [switch]$AsJson,
    [switch]$Copy
)

$Path = Resolve-Path $Path -ErrorAction SilentlyContinue
if (-not $Path) {
    Write-Host "Path not found" -ForegroundColor Red
    exit 1
}

# Initialize context object
$context = [ordered]@{
    path = $Path.ToString()
    name = Split-Path $Path -Leaf
    type = $null
    framework = $null
    dependencies = @()
    scripts = @()
    git = $null
    structure = @()
    environment = [ordered]@{
        os = 'Windows'
        shell = 'PowerShell'
        wsl = (Get-Command wsl -ErrorAction SilentlyContinue) -ne $null
    }
}

# Detect project type
function Get-ProjectType {
    param([string]$ProjectPath)
    
    $types = @()
    $framework = $null
    
    # Check Laravel first
    if ((Test-Path "$ProjectPath\artisan") -and (Test-Path "$ProjectPath\composer.json")) {
        $composer = Get-Content "$ProjectPath\composer.json" -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($composer.require.'laravel/framework') {
            return @{ type = 'PHP'; framework = 'Laravel' }
        }
    }
    
    # Check Symfony
    if (Test-Path "$ProjectPath\symfony.lock") {
        return @{ type = 'PHP'; framework = 'Symfony' }
    }
    
    # Check Node/React/Vue
    if (Test-Path "$ProjectPath\package.json") {
        $pkg = Get-Content "$ProjectPath\package.json" -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($pkg.dependencies.react -or $pkg.devDependencies.react) {
            $fw = 'React'
            if ($pkg.dependencies.next -or $pkg.devDependencies.next) { $fw = 'Next.js' }
            return @{ type = 'JavaScript/Node'; framework = $fw }
        }
        if ($pkg.dependencies.vue -or $pkg.devDependencies.vue) {
            $fw = 'Vue'
            if ($pkg.dependencies.nuxt -or $pkg.devDependencies.nuxt) { $fw = 'Nuxt' }
            return @{ type = 'JavaScript/Node'; framework = $fw }
        }
        if ($pkg.dependencies.express) {
            return @{ type = 'JavaScript/Node'; framework = 'Express' }
        }
        return @{ type = 'JavaScript/Node'; framework = $null }
    }
    
    # Check PHP
    if ((Test-Path "$ProjectPath\composer.json") -or (Get-ChildItem "$ProjectPath\*.php" -ErrorAction SilentlyContinue | Select-Object -First 1)) {
        return @{ type = 'PHP'; framework = $null }
    }
    
    # Check Perl
    if ((Test-Path "$ProjectPath\Makefile.PL") -or (Test-Path "$ProjectPath\cpanfile") -or 
        (Get-ChildItem "$ProjectPath\*.pl" -ErrorAction SilentlyContinue | Select-Object -First 1) -or
        (Get-ChildItem "$ProjectPath\*.pm" -ErrorAction SilentlyContinue | Select-Object -First 1)) {
        return @{ type = 'Perl'; framework = $null }
    }
    
    # Check Python
    if ((Test-Path "$ProjectPath\requirements.txt") -or (Test-Path "$ProjectPath\pyproject.toml") -or (Test-Path "$ProjectPath\setup.py")) {
        $fw = $null
        if (Test-Path "$ProjectPath\manage.py") { $fw = 'Django' }
        if ((Test-Path "$ProjectPath\app.py") -or (Test-Path "$ProjectPath\wsgi.py")) { $fw = 'Flask' }
        return @{ type = 'Python'; framework = $fw }
    }
    
    return @{ type = 'Unknown'; framework = $null }
}

# Get dependencies
function Get-Dependencies {
    param([string]$ProjectPath)
    
    $deps = @()
    
    # Node dependencies
    if (Test-Path "$ProjectPath\package.json") {
        $pkg = Get-Content "$ProjectPath\package.json" -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($pkg.dependencies) {
            $pkg.dependencies.PSObject.Properties | ForEach-Object {
                $deps += @{ name = $_.Name; version = $_.Value; type = 'npm' }
            }
        }
    }
    
    # PHP dependencies
    if (Test-Path "$ProjectPath\composer.json") {
        $composer = Get-Content "$ProjectPath\composer.json" -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($composer.require) {
            $composer.require.PSObject.Properties | Where-Object { $_.Name -ne 'php' } | ForEach-Object {
                $deps += @{ name = $_.Name; version = $_.Value; type = 'composer' }
            }
        }
    }
    
    # Perl dependencies
    if (Test-Path "$ProjectPath\cpanfile") {
        Get-Content "$ProjectPath\cpanfile" | ForEach-Object {
            if ($_ -match "requires\s+'([^']+)'") {
                $deps += @{ name = $Matches[1]; version = '*'; type = 'cpan' }
            }
        }
    }
    
    # Python dependencies
    if (Test-Path "$ProjectPath\requirements.txt") {
        Get-Content "$ProjectPath\requirements.txt" | ForEach-Object {
            if ($_ -match '^([a-zA-Z0-9_-]+)') {
                $deps += @{ name = $Matches[1]; version = '*'; type = 'pip' }
            }
        }
    }
    
    return $deps
}

# Get available scripts
function Get-AvailableScripts {
    param([string]$ProjectPath)
    
    $scripts = @()
    
    # NPM scripts
    if (Test-Path "$ProjectPath\package.json") {
        $pkg = Get-Content "$ProjectPath\package.json" -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($pkg.scripts) {
            $pkg.scripts.PSObject.Properties | ForEach-Object {
                $scripts += @{ name = "npm run $($_.Name)"; command = $_.Value }
            }
        }
    }
    
    # Composer scripts
    if (Test-Path "$ProjectPath\composer.json") {
        $composer = Get-Content "$ProjectPath\composer.json" -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($composer.scripts) {
            $composer.scripts.PSObject.Properties | ForEach-Object {
                $scripts += @{ name = "composer $($_.Name)"; command = $_.Value }
            }
        }
    }
    
    # Laravel artisan
    if (Test-Path "$ProjectPath\artisan") {
        $scripts += @{ name = 'php artisan (art)'; command = 'Laravel CLI' }
    }
    
    return $scripts
}

# Get git info
function Get-GitInfo {
    param([string]$ProjectPath)
    
    if (-not (Test-Path "$ProjectPath\.git")) { return $null }
    
    Push-Location $ProjectPath
    try {
        $branch = git branch --show-current 2>$null
        $status = git status --porcelain 2>$null
        $remotes = git remote -v 2>$null | Select-Object -First 1
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
        
        $modified = ($status | Where-Object { $_ -match '^\s*M' }).Count
        $added = ($status | Where-Object { $_ -match '^\?\?' }).Count
        $deleted = ($status | Where-Object { $_ -match '^\s*D' }).Count
        
        return [ordered]@{
            branch = $branch
            remote = if ($remotes -match '\s+(\S+)\s+') { $Matches[1] } else { $null }
            ahead = $ahead
            behind = $behind
            modified = $modified
            untracked = $added
            deleted = $deleted
            clean = ($status.Count -eq 0)
        }
    } finally {
        Pop-Location
    }
}

# Get directory structure (top level)
function Get-ProjectStructure {
    param([string]$ProjectPath)
    
    $items = Get-ChildItem $ProjectPath -Force | Where-Object { 
        $_.Name -notin @('node_modules', 'vendor', '.git', '__pycache__', '.idea', '.vscode', 'venv', '.venv')
    } | Sort-Object { -not $_.PSIsContainer }, Name | Select-Object -First 20
    
    $structure = @()
    foreach ($item in $items) {
        $type = if ($item.PSIsContainer) { 'dir' } else { 'file' }
        $structure += @{ name = $item.Name; type = $type }
    }
    
    return $structure
}

# Build context
$projectType = Get-ProjectType -ProjectPath $Path
$context.type = $projectType.type
$context.framework = $projectType.framework
$context.dependencies = Get-Dependencies -ProjectPath $Path
$context.scripts = Get-AvailableScripts -ProjectPath $Path
$context.git = Get-GitInfo -ProjectPath $Path
$context.structure = Get-ProjectStructure -ProjectPath $Path

# Output
if ($AsJson) {
    $output = $context | ConvertTo-Json -Depth 10
    if ($Copy) {
        $output | Set-Clipboard
        Write-Host "JSON context copied to clipboard" -ForegroundColor Green
    }
    $output
    exit 0
}

# Text output
$output = ""

if ($Brief) {
    $output = @"
Project: $($context.name)
Type: $($context.type)$(if ($context.framework) { " ($($context.framework))" })
Path: $($context.path)
$(if ($context.git) { "Branch: $($context.git.branch)$(if (-not $context.git.clean) { ' (modified)' })" })
Dependencies: $($context.dependencies.Count)
"@
} else {
    $output = @"
================================================================================
PROJECT CONTEXT: $($context.name)
================================================================================

TYPE: $($context.type)$(if ($context.framework) { " / $($context.framework)" })
PATH: $($context.path)

"@

    if ($context.git) {
        $gitStatus = if ($context.git.clean) { "clean" } else { "$($context.git.modified)M $($context.git.untracked)? $($context.git.deleted)D" }
        $output += @"
GIT:
  Branch: $($context.git.branch)
  Remote: $($context.git.remote)
  Status: $gitStatus
  $(if ($context.git.ahead -gt 0) { "Ahead: $($context.git.ahead) commits" })
  $(if ($context.git.behind -gt 0) { "Behind: $($context.git.behind) commits" })

"@
    }

    $output += @"
STRUCTURE:
"@
    foreach ($item in $context.structure) {
        $icon = if ($item.type -eq 'dir') { '[D]' } else { '[F]' }
        $output += "`n  $icon $($item.name)"
    }

    if ($context.dependencies.Count -gt 0) {
        $output += "`n`nDEPENDENCIES ($($context.dependencies.Count)):"
        $grouped = $context.dependencies | Group-Object { $_.type }
        foreach ($group in $grouped) {
            $output += "`n  [$($group.Name)]"
            $group.Group | Select-Object -First 10 | ForEach-Object {
                $output += "`n    - $($_.name)"
            }
            if ($group.Group.Count -gt 10) {
                $output += "`n    ... and $($group.Group.Count - 10) more"
            }
        }
    }

    if ($context.scripts.Count -gt 0) {
        $output += "`n`nAVAILABLE SCRIPTS:"
        foreach ($script in $context.scripts | Select-Object -First 10) {
            $output += "`n  - $($script.name)"
        }
    }

    $output += @"

================================================================================
ENVIRONMENT: Windows / PowerShell$(if ($context.environment.wsl) { ' / WSL available' })
================================================================================
"@
}

if ($Copy) {
    $output | Set-Clipboard
    Write-Host "Context copied to clipboard" -ForegroundColor Green
    Write-Host ""
}

Write-Output $output
