function Start-DevServer {
    <#
    .SYNOPSIS
        Quick dev server launcher based on project type.

    .DESCRIPTION
        Auto-detects project type and starts the appropriate development server.

    .PARAMETER Type
        Force a specific server type: node, php, python, laravel.

    .PARAMETER Port
        Override the default port.

    .PARAMETER BindHost
        Host to bind to (default: localhost).

    .EXAMPLE
        Start-DevServer
        serve -Port 8080
        serve php
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [ValidateSet('node', 'php', 'python', 'laravel', 'auto', '')]
        [string]$Type = 'auto',

        [int]$Port,

        [string]$BindHost = 'localhost'
    )

    function Get-DevProjectType {
        if (Test-Path '.\artisan') {
            return 'laravel'
        }
        if (Test-Path '.\package.json') {
            return 'node'
        }
        if ((Test-Path '.\index.php') -or (Test-Path '.\public\index.php') -or (Test-Path '.\composer.json')) {
            return 'php'
        }
        if ((Test-Path '.\manage.py') -or (Test-Path '.\app.py') -or (Test-Path '.\main.py')) {
            return 'python'
        }
        return $null
    }

    if ($Type -eq 'auto' -or [string]::IsNullOrEmpty($Type)) {
        $Type = Get-DevProjectType
        if (-not $Type) {
            Write-Host ""
            Write-Host "Could not detect project type." -ForegroundColor Red
            Write-Host "Specify type: serve node | serve php | serve python | serve laravel" -ForegroundColor Yellow
            Write-Host ""
            return
        }
        Write-Host ""
        Write-Host "Detected: " -NoNewline -ForegroundColor Cyan
        Write-Host $Type -ForegroundColor Green
    }

    $defaultPorts = @{
        'node' = 3000
        'php' = 8000
        'python' = 8000
        'laravel' = 8000
    }

    if (-not $Port) {
        $Port = $defaultPorts[$Type]
    }

    $portInUse = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    if ($portInUse) {
        Write-Host ""
        Write-Host "Port $Port is already in use!" -ForegroundColor Red
        Write-Host "Use " -NoNewline -ForegroundColor Gray
        Write-Host "port $Port" -NoNewline -ForegroundColor Yellow
        Write-Host " to see what's using it, or " -NoNewline -ForegroundColor Gray
        Write-Host "serve -Port <number>" -NoNewline -ForegroundColor Yellow
        Write-Host " to use a different port." -ForegroundColor Gray
        Write-Host ""
        return
    }

    Write-Host ""
    Write-Host "Starting $Type dev server on " -NoNewline -ForegroundColor Cyan
    Write-Host "http://${BindHost}:${Port}" -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to stop" -ForegroundColor DarkGray
    Write-Host ""

    switch ($Type) {
        'node' {
            if (Test-Path '.\package.json') {
                $pkg = Get-Content '.\package.json' -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue

                $devScripts = @('dev', 'start', 'serve', 'develop')
                $script = $devScripts | Where-Object { $pkg.scripts.$_ } | Select-Object -First 1

                if ($script) {
                    Write-Host "Running: npm run $script" -ForegroundColor DarkGray
                    Write-Host ""
                    npm run $script
                } else {
                    Write-Host "No dev script found in package.json" -ForegroundColor Yellow
                    Write-Host "Available scripts: $($pkg.scripts.PSObject.Properties.Name -join ', ')" -ForegroundColor DarkGray
                }
            } else {
                Write-Host "No package.json found" -ForegroundColor Red
            }
        }

        'php' {
            $docRoot = '.'
            if (Test-Path '.\public') {
                $docRoot = '.\public'
            } elseif (Test-Path '.\web') {
                $docRoot = '.\web'
            } elseif (Test-Path '.\htdocs') {
                $docRoot = '.\htdocs'
            }

            Write-Host "Document root: $docRoot" -ForegroundColor DarkGray
            Write-Host ""
            php -S "${BindHost}:${Port}" -t $docRoot
        }

        'laravel' {
            Write-Host "Running: php artisan serve --port=$Port" -ForegroundColor DarkGray
            Write-Host ""
            php artisan serve --host=$BindHost --port=$Port
        }

        'python' {
            if (Test-Path '.\manage.py') {
                Write-Host "Running: python manage.py runserver ${Port}" -ForegroundColor DarkGray
                Write-Host ""
                python manage.py runserver "${BindHost}:${Port}"
            }
            elseif (Test-Path '.\app.py') {
                Write-Host "Running: flask run --port $Port" -ForegroundColor DarkGray
                Write-Host ""
                $env:FLASK_APP = 'app.py'
                $env:FLASK_ENV = 'development'
                flask run --host=$BindHost --port=$Port
            }
            elseif (Test-Path '.\main.py') {
                Write-Host "Running: uvicorn main:app --port $Port" -ForegroundColor DarkGray
                Write-Host ""
                uvicorn main:app --host $BindHost --port $Port --reload
            }
            else {
                Write-Host "Running: python -m http.server $Port" -ForegroundColor DarkGray
                Write-Host ""
                python -m http.server $Port --bind $BindHost
            }
        }
    }
}
