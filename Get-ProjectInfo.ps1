<#
.SYNOPSIS
    Detect and display project type and information.

.DESCRIPTION
    Detects the project type (Node/React, PHP/Laravel, Perl, Python)
    and shows relevant information like dependencies, scripts, and structure.

.PARAMETER Path
    Path to project directory (defaults to current directory).

.PARAMETER AsJson
    Output as JSON for MCP tools.

.EXAMPLE
    proj
    proj C:\Dev\myapp
    proj -AsJson
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Path = '.',

    [switch]$AsJson
)

$Path = Resolve-Path $Path -ErrorAction SilentlyContinue
if (-not $Path) {
    Write-Host "Path not found" -ForegroundColor Red
    exit 1
}

$info = [ordered]@{
    name = Split-Path $Path -Leaf
    path = $Path.ToString()
    type = 'Unknown'
    framework = $null
    version = $null
    scripts = @()
    dependencies = 0
    devDependencies = 0
    hasGit = Test-Path "$Path\.git"
    hasTests = $false
    hasDocker = (Test-Path "$Path\Dockerfile") -or (Test-Path "$Path\docker-compose.yml")
}

# Detect Node.js / React
if (Test-Path "$Path\package.json") {
    $pkg = Get-Content "$Path\package.json" -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
    
    $info.type = 'Node.js'
    $info.name = $pkg.name
    $info.version = $pkg.version
    
    # Detect framework
    if ($pkg.dependencies.react -or $pkg.devDependencies.react) {
        $info.framework = 'React'
        if ($pkg.dependencies.next -or $pkg.devDependencies.next) { $info.framework = 'Next.js' }
    } elseif ($pkg.dependencies.vue -or $pkg.devDependencies.vue) {
        $info.framework = 'Vue'
        if ($pkg.dependencies.nuxt -or $pkg.devDependencies.nuxt) { $info.framework = 'Nuxt' }
    } elseif ($pkg.dependencies.express) {
        $info.framework = 'Express'
    } elseif ($pkg.dependencies.'@nestjs/core') {
        $info.framework = 'NestJS'
    }
    
    # Count dependencies
    $info.dependencies = if ($pkg.dependencies) { ($pkg.dependencies | Get-Member -MemberType NoteProperty).Count } else { 0 }
    $info.devDependencies = if ($pkg.devDependencies) { ($pkg.devDependencies | Get-Member -MemberType NoteProperty).Count } else { 0 }
    
    # Get scripts
    if ($pkg.scripts) {
        $info.scripts = $pkg.scripts | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
    }
    
    # Check for tests
    $info.hasTests = (Test-Path "$Path\tests") -or (Test-Path "$Path\__tests__") -or 
                     (Test-Path "$Path\test") -or ($info.scripts -contains 'test')
}
# Detect PHP / Laravel / Symfony
elseif (Test-Path "$Path\composer.json") {
    $composer = Get-Content "$Path\composer.json" -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
    
    $info.type = 'PHP'
    $info.name = $composer.name
    
    # Detect framework
    if (Test-Path "$Path\artisan") {
        $info.framework = 'Laravel'
        # Get Laravel version
        if ($composer.require.'laravel/framework') {
            $info.version = $composer.require.'laravel/framework'
        }
    } elseif (Test-Path "$Path\symfony.lock") {
        $info.framework = 'Symfony'
    } elseif (Test-Path "$Path\wp-config.php") {
        $info.framework = 'WordPress'
    }
    
    # Count dependencies
    $info.dependencies = if ($composer.require) { ($composer.require | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -ne 'php' }).Count } else { 0 }
    $info.devDependencies = if ($composer.'require-dev') { ($composer.'require-dev' | Get-Member -MemberType NoteProperty).Count } else { 0 }
    
    # Get scripts
    if ($composer.scripts) {
        $info.scripts = $composer.scripts | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
    }
    
    # Check for tests
    $info.hasTests = (Test-Path "$Path\tests") -or (Test-Path "$Path\phpunit.xml") -or (Test-Path "$Path\phpunit.xml.dist")
}
# Detect Perl
elseif ((Test-Path "$Path\Makefile.PL") -or (Test-Path "$Path\cpanfile")) {
    $info.type = 'Perl'
    
    # Try to get module name from Makefile.PL
    if (Test-Path "$Path\Makefile.PL") {
        $makefile = Get-Content "$Path\Makefile.PL" -Raw
        if ($makefile -match "NAME\s*=>\s*'([^']+)'") {
            $info.name = $Matches[1]
        }
    }
    
    # Count dependencies from cpanfile
    if (Test-Path "$Path\cpanfile") {
        $cpanfile = Get-Content "$Path\cpanfile"
        $info.dependencies = ($cpanfile | Where-Object { $_ -match '^\s*requires\s+' }).Count
        $info.devDependencies = ($cpanfile | Where-Object { $_ -match '^\s*test_requires\s+' }).Count
    }
    
    # Check for tests
    $info.hasTests = Test-Path "$Path\t"
    
    $info.scripts = @('perl Makefile.PL', 'make', 'make test', 'make install')
}
# Detect Python
elseif ((Test-Path "$Path\requirements.txt") -or (Test-Path "$Path\pyproject.toml") -or (Test-Path "$Path\setup.py")) {
    $info.type = 'Python'
    
    # Detect framework
    if (Test-Path "$Path\manage.py") {
        $info.framework = 'Django'
    } elseif ((Test-Path "$Path\app.py") -and (Get-Content "$Path\app.py" -Raw -ErrorAction SilentlyContinue) -match 'Flask') {
        $info.framework = 'Flask'
    } elseif (Test-Path "$Path\main.py") {
        $main = Get-Content "$Path\main.py" -Raw -ErrorAction SilentlyContinue
        if ($main -match 'FastAPI') { $info.framework = 'FastAPI' }
    }
    
    # Count dependencies
    if (Test-Path "$Path\requirements.txt") {
        $info.dependencies = (Get-Content "$Path\requirements.txt" | Where-Object { $_ -match '^[a-zA-Z]' }).Count
    }
    
    # Check for tests
    $info.hasTests = (Test-Path "$Path\tests") -or (Test-Path "$Path\test") -or (Test-Path "$Path\pytest.ini")
    
    $info.scripts = @('pip install -r requirements.txt', 'python main.py', 'pytest')
}

# JSON output
if ($AsJson) {
    $info | ConvertTo-Json -Depth 5
    exit 0
}

# Pretty output
Write-Host ""
Write-Host "Project: " -NoNewline -ForegroundColor Cyan
Write-Host $info.name -ForegroundColor Yellow
Write-Host ""

Write-Host "  Type:       " -NoNewline -ForegroundColor Gray
Write-Host $info.type -NoNewline -ForegroundColor White
if ($info.framework) {
    Write-Host " / $($info.framework)" -ForegroundColor Green
} else {
    Write-Host ""
}

if ($info.version) {
    Write-Host "  Version:    " -NoNewline -ForegroundColor Gray
    Write-Host $info.version -ForegroundColor White
}

Write-Host "  Path:       " -NoNewline -ForegroundColor Gray
Write-Host $info.path -ForegroundColor DarkGray

Write-Host ""
Write-Host "  Dependencies:     " -NoNewline -ForegroundColor Gray
Write-Host $info.dependencies -ForegroundColor White
Write-Host "  Dev Dependencies: " -NoNewline -ForegroundColor Gray
Write-Host $info.devDependencies -ForegroundColor White

Write-Host ""
Write-Host "  Git:    " -NoNewline -ForegroundColor Gray
Write-Host $(if ($info.hasGit) { "Yes" } else { "No" }) -ForegroundColor $(if ($info.hasGit) { 'Green' } else { 'DarkGray' })
Write-Host "  Tests:  " -NoNewline -ForegroundColor Gray
Write-Host $(if ($info.hasTests) { "Yes" } else { "No" }) -ForegroundColor $(if ($info.hasTests) { 'Green' } else { 'DarkGray' })
Write-Host "  Docker: " -NoNewline -ForegroundColor Gray
Write-Host $(if ($info.hasDocker) { "Yes" } else { "No" }) -ForegroundColor $(if ($info.hasDocker) { 'Green' } else { 'DarkGray' })

if ($info.scripts.Count -gt 0) {
    Write-Host ""
    Write-Host "  Scripts:" -ForegroundColor Cyan
    $info.scripts | Select-Object -First 8 | ForEach-Object {
        Write-Host "    - $_" -ForegroundColor White
    }
    if ($info.scripts.Count -gt 8) {
        Write-Host "    ... and $($info.scripts.Count - 8) more" -ForegroundColor DarkGray
    }
}

Write-Host ""
