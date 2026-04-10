function Set-ProjectEnv {
    <#
    .SYNOPSIS
        Load .env files into the current PowerShell session.

    .DESCRIPTION
        Parses a .env file and sets environment variables in the current session.
        Can also display current environment variables (with sensitive values redacted).

    .PARAMETER Path
        Path to .env file (defaults to .env in current directory).

    .PARAMETER Show
        Show current environment variables (redacts sensitive values).

    .PARAMETER List
        List variables that would be set without setting them.

    .PARAMETER Unload
        Remove previously loaded variables from this session.

    .EXAMPLE
        Set-ProjectEnv
        useenv .env.local
        useenv -Show
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Path = '.\.env',

        [switch]$Show,
        [switch]$List,
        [switch]$Unload
    )

    if (-not $global:LoadedEnvVars) { $global:LoadedEnvVars = @() }

    $sensitivePatterns = @(
        'PASSWORD', 'SECRET', 'KEY', 'TOKEN', 'CREDENTIAL', 'AUTH',
        'PRIVATE', 'API_KEY', 'APIKEY', 'ACCESS', 'ENCRYPT'
    )

    function Test-Sensitive {
        param([string]$Name)
        foreach ($pattern in $sensitivePatterns) {
            if ($Name -match $pattern) { return $true }
        }
        return $false
    }

    function Get-RedactedValue {
        param([string]$Name, [string]$Value)
        if (Test-Sensitive $Name) {
            if ($Value.Length -le 4) { return '****' }
            return $Value.Substring(0, 2) + ('*' * [Math]::Min(20, $Value.Length - 4)) + $Value.Substring($Value.Length - 2)
        }
        return $Value
    }

    if ($Show) {
        Write-Host ""
        Write-Host "Current Environment Variables" -ForegroundColor Cyan
        Write-Host "=============================" -ForegroundColor Cyan
        Write-Host ""

        $devVars = @(
            'NODE_ENV', 'APP_ENV', 'DEBUG', 'LOG_LEVEL',
            'DATABASE_URL', 'DB_HOST', 'DB_DATABASE', 'DB_USERNAME', 'DB_PASSWORD',
            'REDIS_HOST', 'CACHE_DRIVER',
            'API_URL', 'API_KEY', 'APP_KEY', 'SECRET_KEY',
            'AWS_ACCESS_KEY_ID', 'AWS_SECRET_ACCESS_KEY', 'AWS_REGION',
            'MAIL_HOST', 'MAIL_USERNAME'
        )

        $found = @()
        foreach ($var in $devVars) {
            $value = [Environment]::GetEnvironmentVariable($var)
            if ($value) {
                $found += [PSCustomObject]@{
                    Name = $var
                    Value = Get-RedactedValue $var $value
                }
            }
        }

        if ($found.Count -gt 0) {
            $found | ForEach-Object {
                Write-Host "  $($_.Name.PadRight(25))" -NoNewline -ForegroundColor Yellow
                Write-Host $_.Value -ForegroundColor White
            }
        } else {
            Write-Host "  No common dev environment variables set." -ForegroundColor DarkGray
        }

        if ($global:LoadedEnvVars -and $global:LoadedEnvVars.Count -gt 0) {
            Write-Host ""
            Write-Host "Loaded from .env:" -ForegroundColor Cyan
            foreach ($var in $global:LoadedEnvVars) {
                $value = [Environment]::GetEnvironmentVariable($var)
                Write-Host "  $($var.PadRight(25))" -NoNewline -ForegroundColor Green
                Write-Host (Get-RedactedValue $var $value) -ForegroundColor White
            }
        }

        Write-Host ""
        return
    }

    if ($Unload) {
        if ($global:LoadedEnvVars -and $global:LoadedEnvVars.Count -gt 0) {
            foreach ($var in $global:LoadedEnvVars) {
                Remove-Item "Env:$var" -ErrorAction SilentlyContinue
                Write-Host "  Removed: $var" -ForegroundColor Yellow
            }
            $global:LoadedEnvVars = @()
            Write-Host ""
            Write-Host "Environment variables unloaded." -ForegroundColor Green
        } else {
            Write-Host "No environment variables to unload." -ForegroundColor Yellow
        }
        Write-Host ""
        return
    }

    if (-not (Test-Path $Path)) {
        Write-Host ""
        Write-Host "File not found: $Path" -ForegroundColor Red
        Write-Host ""

        $alternatives = @('.env', '.env.local', '.env.development', '.env.example')
        $found = $alternatives | Where-Object { Test-Path $_ }
        if ($found) {
            Write-Host "Available .env files:" -ForegroundColor Cyan
            $found | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
            Write-Host ""
        }
        return
    }

    $envVars = @()
    $content = Get-Content $Path

    foreach ($line in $content) {
        if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith('#')) {
            continue
        }

        if ($line -match '^([^=]+)=(.*)$') {
            $name = $Matches[1].Trim()
            $value = $Matches[2].Trim()

            if (($value.StartsWith('"') -and $value.EndsWith('"')) -or
                ($value.StartsWith("'") -and $value.EndsWith("'"))) {
                $value = $value.Substring(1, $value.Length - 2)
            }

            if (-not ($Matches[2].Trim().StartsWith('"') -or $Matches[2].Trim().StartsWith("'"))) {
                if ($value -match '^([^#]*?)\s+#') {
                    $value = $Matches[1].Trim()
                }
            }

            $envVars += [PSCustomObject]@{
                Name = $name
                Value = $value
            }
        }
    }

    if ($List) {
        Write-Host ""
        Write-Host "Variables in $Path" -ForegroundColor Cyan
        Write-Host ("=" * 40) -ForegroundColor Cyan
        Write-Host ""

        foreach ($var in $envVars) {
            Write-Host "  $($var.Name.PadRight(25))" -NoNewline -ForegroundColor Yellow
            Write-Host (Get-RedactedValue $var.Name $var.Value) -ForegroundColor White
        }
        Write-Host ""
        Write-Host "Total: $($envVars.Count) variables" -ForegroundColor Gray
        Write-Host ""
        return
    }

    Write-Host ""
    Write-Host "Loading $Path" -ForegroundColor Cyan
    Write-Host ""

    $loaded = @()
    foreach ($var in $envVars) {
        [Environment]::SetEnvironmentVariable($var.Name, $var.Value, 'Process')
        $loaded += $var.Name
        Write-Host "  Set: $($var.Name)" -ForegroundColor Green
    }

    $global:LoadedEnvVars = $loaded

    Write-Host ""
    Write-Host "Loaded $($loaded.Count) environment variables." -ForegroundColor Green
    Write-Host "Use " -NoNewline -ForegroundColor Gray
    Write-Host "useenv -Show" -NoNewline -ForegroundColor Yellow
    Write-Host " to view or " -NoNewline -ForegroundColor Gray
    Write-Host "useenv -Unload" -NoNewline -ForegroundColor Yellow
    Write-Host " to remove." -ForegroundColor Gray
    Write-Host ""
}
