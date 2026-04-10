$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Import-Module (Join-Path $repoRoot "PowerShellDevToolkit") -Force

Describe "Get-ProjectInfo" {
    It "Should detect Node.js project" {
        $dir = Join-Path $env:TEMP "pester-projinfo-node-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            @{ name = "test-app"; version = "1.0.0"; dependencies = @{}; scripts = @{ dev = "node index.js" } } |
                ConvertTo-Json | Set-Content "$dir\package.json"
            $raw = Get-ProjectInfo -Path $dir -AsJson 2>$null
            $result = $raw | ConvertFrom-Json
            $result.type | Should Be 'Node.js'
            $result.name | Should Be 'test-app'
            $result.version | Should Be '1.0.0'
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should detect React framework" {
        $dir = Join-Path $env:TEMP "pester-projinfo-react-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            @{ name = "react-app"; dependencies = @{ react = "^18.0.0"; "react-dom" = "^18.0.0" } } |
                ConvertTo-Json | Set-Content "$dir\package.json"
            $raw = Get-ProjectInfo -Path $dir -AsJson 2>$null
            $result = $raw | ConvertFrom-Json
            $result.type | Should Be 'Node.js'
            $result.framework | Should Be 'React'
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should detect Next.js framework" {
        $dir = Join-Path $env:TEMP "pester-projinfo-next-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            @{ name = "next-app"; dependencies = @{ react = "^18.0.0"; next = "^14.0.0" } } |
                ConvertTo-Json | Set-Content "$dir\package.json"
            $raw = Get-ProjectInfo -Path $dir -AsJson 2>$null
            $result = $raw | ConvertFrom-Json
            $result.framework | Should Be 'Next.js'
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should detect Vue framework" {
        $dir = Join-Path $env:TEMP "pester-projinfo-vue-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            @{ name = "vue-app"; dependencies = @{ vue = "^3.0.0" } } |
                ConvertTo-Json | Set-Content "$dir\package.json"
            $raw = Get-ProjectInfo -Path $dir -AsJson 2>$null
            $result = $raw | ConvertFrom-Json
            $result.framework | Should Be 'Vue'
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should detect Express framework" {
        $dir = Join-Path $env:TEMP "pester-projinfo-express-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            @{ name = "api"; dependencies = @{ express = "^4.0.0" } } |
                ConvertTo-Json | Set-Content "$dir\package.json"
            $raw = Get-ProjectInfo -Path $dir -AsJson 2>$null
            $result = $raw | ConvertFrom-Json
            $result.framework | Should Be 'Express'
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should detect PHP/Laravel project" {
        $dir = Join-Path $env:TEMP "pester-projinfo-laravel-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            @{ name = "laravel-app"; require = @{ "laravel/framework" = "^10.0" } } |
                ConvertTo-Json | Set-Content "$dir\composer.json"
            Set-Content "$dir\artisan" "#!/usr/bin/env php"
            $raw = Get-ProjectInfo -Path $dir -AsJson 2>$null
            $result = $raw | ConvertFrom-Json
            $result.type | Should Be 'PHP'
            $result.framework | Should Be 'Laravel'
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should detect Perl project" {
        $dir = Join-Path $env:TEMP "pester-projinfo-perl-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            Set-Content "$dir\cpanfile" "requires 'Mojolicious';`nrequires 'DBI';"
            $raw = Get-ProjectInfo -Path $dir -AsJson 2>$null
            $result = $raw | ConvertFrom-Json
            $result.type | Should Be 'Perl'
            $result.dependencies | Should Be 2
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should detect Python project" {
        $dir = Join-Path $env:TEMP "pester-projinfo-python-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            Set-Content "$dir\requirements.txt" "flask==2.0`nrequests==2.28`n"
            $raw = Get-ProjectInfo -Path $dir -AsJson 2>$null
            $result = $raw | ConvertFrom-Json
            $result.type | Should Be 'Python'
            $result.dependencies | Should Be 2
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should detect Django framework" {
        $dir = Join-Path $env:TEMP "pester-projinfo-django-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            Set-Content "$dir\requirements.txt" "django==4.2`n"
            Set-Content "$dir\manage.py" "#!/usr/bin/env python"
            $raw = Get-ProjectInfo -Path $dir -AsJson 2>$null
            $result = $raw | ConvertFrom-Json
            $result.framework | Should Be 'Django'
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should report Unknown for empty directory" {
        $dir = Join-Path $env:TEMP "pester-projinfo-empty-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            $raw = Get-ProjectInfo -Path $dir -AsJson 2>$null
            $result = $raw | ConvertFrom-Json
            $result.type | Should Be 'Unknown'
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should include hasGit, hasDocker, hasTests fields" {
        $dir = Join-Path $env:TEMP "pester-projinfo-fields-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            @{ name = "test"; dependencies = @{} } | ConvertTo-Json | Set-Content "$dir\package.json"
            $raw = Get-ProjectInfo -Path $dir -AsJson 2>$null
            $result = $raw | ConvertFrom-Json
            ($null -ne $result.hasGit) | Should Be $true
            ($null -ne $result.hasDocker) | Should Be $true
            ($null -ne $result.hasTests) | Should Be $true
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should count dependencies correctly" {
        $dir = Join-Path $env:TEMP "pester-projinfo-deps-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            @{
                name = "dep-test"
                dependencies = @{ react = "^18"; axios = "^1"; lodash = "^4" }
                devDependencies = @{ jest = "^29"; eslint = "^8" }
            } | ConvertTo-Json | Set-Content "$dir\package.json"
            $raw = Get-ProjectInfo -Path $dir -AsJson 2>$null
            $result = $raw | ConvertFrom-Json
            $result.dependencies | Should Be 3
            $result.devDependencies | Should Be 2
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should detect test directories" {
        $dir = Join-Path $env:TEMP "pester-projinfo-tests-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            @{ name = "with-tests"; dependencies = @{} } | ConvertTo-Json | Set-Content "$dir\package.json"
            New-Item -Path "$dir\tests" -ItemType Directory -Force | Out-Null
            $raw = Get-ProjectInfo -Path $dir -AsJson 2>$null
            $result = $raw | ConvertFrom-Json
            $result.hasTests | Should Be $true
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
