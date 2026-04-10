$scriptDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Describe "Get-ProjectContext" {
    It "Should detect Laravel project" {
        $dir = Join-Path $env:TEMP "pester-ctx-laravel-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            @{ require = @{ "laravel/framework" = "^10.0" } } | ConvertTo-Json | Set-Content "$dir\composer.json"
            Set-Content "$dir\artisan" "#!/usr/bin/env php"
            $raw = & "$scriptDir\Get-ProjectContext.ps1" -Path $dir -AsJson 2>$null
            $result = $raw | ConvertFrom-Json
            $result.type | Should Be 'PHP'
            $result.framework | Should Be 'Laravel'
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should detect Express project" {
        $dir = Join-Path $env:TEMP "pester-ctx-express-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            @{ dependencies = @{ express = "^4.0.0" } } | ConvertTo-Json | Set-Content "$dir\package.json"
            $raw = & "$scriptDir\Get-ProjectContext.ps1" -Path $dir -AsJson 2>$null
            $result = $raw | ConvertFrom-Json
            $result.framework | Should Be 'Express'
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should detect Python/Django project" {
        $dir = Join-Path $env:TEMP "pester-ctx-django-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            Set-Content "$dir\requirements.txt" "django==4.2"
            Set-Content "$dir\manage.py" "#!/usr/bin/env python"
            $raw = & "$scriptDir\Get-ProjectContext.ps1" -Path $dir -AsJson 2>$null
            $result = $raw | ConvertFrom-Json
            $result.type | Should Be 'Python'
            $result.framework | Should Be 'Django'
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should count npm dependencies" {
        $dir = Join-Path $env:TEMP "pester-ctx-deps-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            @{ dependencies = @{ react = "^18"; axios = "^1"; lodash = "^4" } } |
                ConvertTo-Json | Set-Content "$dir\package.json"
            $raw = & "$scriptDir\Get-ProjectContext.ps1" -Path $dir -AsJson 2>$null
            $result = $raw | ConvertFrom-Json
            ($result.dependencies | Measure-Object).Count | Should Be 3
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should extract npm scripts" {
        $dir = Join-Path $env:TEMP "pester-ctx-scripts-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            @{ dependencies = @{}; scripts = @{ dev = "vite"; build = "vite build"; test = "jest" } } |
                ConvertTo-Json | Set-Content "$dir\package.json"
            $raw = & "$scriptDir\Get-ProjectContext.ps1" -Path $dir -AsJson 2>$null
            $result = $raw | ConvertFrom-Json
            ($result.scripts | Measure-Object).Count | Should Be 3
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should return directory structure" {
        $dir = Join-Path $env:TEMP "pester-ctx-struct-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            New-Item -Path "$dir\src" -ItemType Directory -Force | Out-Null
            Set-Content "$dir\readme.md" "hello"
            @{ dependencies = @{} } | ConvertTo-Json | Set-Content "$dir\package.json"
            $raw = & "$scriptDir\Get-ProjectContext.ps1" -Path $dir -AsJson 2>$null
            $result = $raw | ConvertFrom-Json
            ($result.structure | Measure-Object).Count | Should BeGreaterThan 0
            $names = $result.structure | ForEach-Object { $_.name }
            ($names -contains 'src') | Should Be $true
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should include environment section" {
        $dir = Join-Path $env:TEMP "pester-ctx-env-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            Set-Content "$dir\requirements.txt" "flask"
            $raw = & "$scriptDir\Get-ProjectContext.ps1" -Path $dir -AsJson 2>$null
            $result = $raw | ConvertFrom-Json
            $result.environment.os | Should Be 'Windows'
            $result.environment.shell | Should Be 'PowerShell'
            ($null -ne $result.environment.wsl) | Should Be $true
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should produce shorter output with -Brief" {
        $dir = Join-Path $env:TEMP "pester-ctx-brief-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            @{ dependencies = @{ react = "^18" } } | ConvertTo-Json | Set-Content "$dir\package.json"
            $full = & "$scriptDir\Get-ProjectContext.ps1" -Path $dir 2>$null | Out-String
            $brief = & "$scriptDir\Get-ProjectContext.ps1" -Path $dir -Brief 2>$null | Out-String
            ($brief.Length -lt $full.Length) | Should Be $true
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
