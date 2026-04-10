<#
.SYNOPSIS
    Check if common development services are running.

.DESCRIPTION
    Shows status of common development services like Node, PHP, Docker,
    MySQL, PostgreSQL, Redis, etc.

.PARAMETER Services
    Specific services to check (optional). If not specified, shows all.

.PARAMETER AsJson
    Output as JSON for MCP tools.

.EXAMPLE
    services                  # Show all common services
    services docker node      # Check specific ones
    services -AsJson          # JSON output
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0, ValueFromRemainingArguments)]
    [string[]]$Services,

    [switch]$AsJson
)

# Service definitions
$serviceChecks = [ordered]@{
    'node' = @{
        name = 'Node.js'
        process = 'node'
        port = $null
        check = { (Get-Process node -ErrorAction SilentlyContinue).Count -gt 0 }
        version = { node --version 2>$null }
    }
    'npm' = @{
        name = 'npm'
        process = $null
        port = $null
        check = { (Get-Command npm -ErrorAction SilentlyContinue) -ne $null }
        version = { npm --version 2>$null }
    }
    'php' = @{
        name = 'PHP'
        process = 'php'
        port = $null
        check = { (Get-Command php -ErrorAction SilentlyContinue) -ne $null }
        version = { php --version 2>$null | Select-Object -First 1 }
    }
    'composer' = @{
        name = 'Composer'
        process = $null
        port = $null
        check = { (Get-Command composer -ErrorAction SilentlyContinue) -ne $null }
        version = { composer --version 2>$null | Select-Object -First 1 }
    }
    'perl' = @{
        name = 'Perl'
        process = 'perl'
        port = $null
        check = { (Get-Command perl -ErrorAction SilentlyContinue) -ne $null }
        version = { perl --version 2>$null | Where-Object { $_ -match 'version' } | Select-Object -First 1 }
    }
    'python' = @{
        name = 'Python'
        process = 'python'
        port = $null
        check = { (Get-Command python -ErrorAction SilentlyContinue) -ne $null }
        version = { python --version 2>$null }
    }
    'docker' = @{
        name = 'Docker'
        process = 'docker'
        port = $null
        check = { 
            $dockerInfo = docker info 2>$null
            $LASTEXITCODE -eq 0
        }
        version = { docker --version 2>$null }
    }
    'mysql' = @{
        name = 'MySQL'
        process = 'mysqld'
        port = 3306
        check = { 
            (Get-Process mysqld -ErrorAction SilentlyContinue) -or
            (Get-NetTCPConnection -LocalPort 3306 -State Listen -ErrorAction SilentlyContinue)
        }
        version = { mysql --version 2>$null }
    }
    'postgres' = @{
        name = 'PostgreSQL'
        process = 'postgres'
        port = 5432
        check = { 
            (Get-Process postgres -ErrorAction SilentlyContinue) -or
            (Get-NetTCPConnection -LocalPort 5432 -State Listen -ErrorAction SilentlyContinue)
        }
        version = { psql --version 2>$null }
    }
    'redis' = @{
        name = 'Redis'
        process = 'redis-server'
        port = 6379
        check = { 
            (Get-Process redis-server -ErrorAction SilentlyContinue) -or
            (Get-NetTCPConnection -LocalPort 6379 -State Listen -ErrorAction SilentlyContinue)
        }
        version = { redis-server --version 2>$null }
    }
    'mongodb' = @{
        name = 'MongoDB'
        process = 'mongod'
        port = 27017
        check = { 
            (Get-Process mongod -ErrorAction SilentlyContinue) -or
            (Get-NetTCPConnection -LocalPort 27017 -State Listen -ErrorAction SilentlyContinue)
        }
        version = { mongod --version 2>$null | Select-Object -First 1 }
    }
    'apache' = @{
        name = 'Apache'
        process = 'httpd', 'apache'
        port = 80
        check = { 
            (Get-Process httpd, apache2 -ErrorAction SilentlyContinue) -or
            (Get-Service -Name 'Apache*' -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Running' })
        }
        version = { httpd -v 2>$null | Select-Object -First 1 }
    }
    'nginx' = @{
        name = 'nginx'
        process = 'nginx'
        port = 80
        check = { 
            (Get-Process nginx -ErrorAction SilentlyContinue) -or
            (Get-Service nginx -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Running' })
        }
        version = { nginx -v 2>&1 }
    }
    'git' = @{
        name = 'Git'
        process = $null
        port = $null
        check = { (Get-Command git -ErrorAction SilentlyContinue) -ne $null }
        version = { git --version 2>$null }
    }
}

# Filter services if specified
$checkList = if ($Services -and $Services.Count -gt 0) {
    $Services | ForEach-Object { $_.ToLower() }
} else {
    $serviceChecks.Keys
}

# Check each service
$results = @()
foreach ($key in $checkList) {
    if (-not $serviceChecks.Contains($key)) {
        $results += [ordered]@{
            id = $key
            name = $key
            status = 'unknown'
            error = 'Unknown service'
        }
        continue
    }
    
    $svc = $serviceChecks[$key]
    $isRunning = $false
    $version = $null
    
    try {
        $isRunning = & $svc.check
        if ($svc.version) {
            $version = & $svc.version
            if ($version -is [array]) { $version = $version -join '' }
            $version = $version -replace '[\r\n]', '' | ForEach-Object { $_.Trim() }
        }
    } catch {
        # Ignore errors
    }
    
    $results += [ordered]@{
        id = $key
        name = $svc.name
        status = if ($isRunning) { 'running' } else { 'stopped' }
        port = $svc.port
        version = $version
    }
}

# JSON output
if ($AsJson) {
    $results | ConvertTo-Json -Depth 5
    exit 0
}

# Pretty output
Write-Host ""
Write-Host "Service Status" -ForegroundColor Cyan
Write-Host "==============" -ForegroundColor Cyan
Write-Host ""

foreach ($result in $results) {
    $statusIcon = if ($result.status -eq 'running') { '●' } 
                  elseif ($result.status -eq 'unknown') { '?' }
                  else { '○' }
    $statusColor = if ($result.status -eq 'running') { 'Green' } 
                   elseif ($result.status -eq 'unknown') { 'Yellow' }
                   else { 'DarkGray' }
    
    Write-Host "  $statusIcon " -NoNewline -ForegroundColor $statusColor
    Write-Host $result.name.PadRight(15) -NoNewline -ForegroundColor White
    
    if ($result.status -eq 'running') {
        Write-Host "running" -NoNewline -ForegroundColor Green
        if ($result.port) {
            Write-Host " :$($result.port)" -NoNewline -ForegroundColor DarkGray
        }
    } elseif ($result.status -eq 'unknown') {
        Write-Host $result.error -ForegroundColor Yellow
        continue
    } else {
        Write-Host "stopped" -NoNewline -ForegroundColor DarkGray
    }
    
    if ($result.version) {
        Write-Host " - $($result.version)" -ForegroundColor DarkGray
    } else {
        Write-Host ""
    }
}

Write-Host ""
