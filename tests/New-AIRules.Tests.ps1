$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Import-Module (Join-Path $repoRoot "PowerShellDevToolkit") -Force

Describe "New-AIRules" {
    It "Should generate .airules file for PHP" {
        $dir = Join-Path $env:TEMP "pester-airules-php-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            $outFile = "$dir\.airules"
            New-AIRules -Language php -OutputPath $outFile 2>$null | Out-Null
            (Test-Path $outFile) | Should Be $true
            $content = Get-Content $outFile -Raw
            ($content -match 'PHP') | Should Be $true
            ($content -match 'PSR-12') | Should Be $true
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should generate .cursorrules with -RuleType Cursor" {
        $dir = Join-Path $env:TEMP "pester-airules-cursor-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            $outFile = "$dir\.cursorrules"
            New-AIRules -Language react -RuleType Cursor -OutputPath $outFile 2>$null | Out-Null
            (Test-Path $outFile) | Should Be $true
            $content = Get-Content $outFile -Raw
            ($content -match 'Cursor AI Rules') | Should Be $true
            ($content -match 'React') | Should Be $true
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should generate .clauderules with -RuleType Claude" {
        $dir = Join-Path $env:TEMP "pester-airules-claude-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            $outFile = "$dir\.clauderules"
            New-AIRules -Language node -RuleType Claude -OutputPath $outFile 2>$null | Out-Null
            (Test-Path $outFile) | Should Be $true
            $content = Get-Content $outFile -Raw
            ($content -match 'Claude AI Rules') | Should Be $true
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should include common header sections" {
        $dir = Join-Path $env:TEMP "pester-airules-header-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            $outFile = "$dir\.airules"
            New-AIRules -Language perl -OutputPath $outFile 2>$null | Out-Null
            $content = Get-Content $outFile -Raw
            ($content -match 'PowerShell Commands') | Should Be $true
            ($content -match 'SSH') | Should Be $true
            ($content -match 'cssh') | Should Be $true
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should auto-detect from project files" {
        $dir = Join-Path $env:TEMP "pester-airules-auto-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            @{ dependencies = @{ react = "^18" } } | ConvertTo-Json | Set-Content "$dir\package.json"
            $outFile = "$dir\.airules"
            Push-Location $dir
            New-AIRules -Auto -OutputPath $outFile 2>$null | Out-Null
            Pop-Location
            (Test-Path $outFile) | Should Be $true
            $content = Get-Content $outFile -Raw
            ($content -match 'React') | Should Be $true
        } finally {
            if ((Get-Location).Path -eq $dir) { Pop-Location }
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should append to existing file with -Append" {
        $dir = Join-Path $env:TEMP "pester-airules-append-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            $outFile = "$dir\.airules"
            Set-Content $outFile "# Existing content`n"
            New-AIRules -Language python -Append -OutputPath $outFile 2>$null | Out-Null
            $content = Get-Content $outFile -Raw
            ($content -match 'Existing content') | Should Be $true
            ($content -match 'Python') | Should Be $true
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should generate all supported languages without error" {
        $dir = Join-Path $env:TEMP "pester-airules-all-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            $languages = @('php', 'laravel', 'symfony', 'react', 'node', 'perl', 'python')
            foreach ($lang in $languages) {
                $outFile = "$dir\$lang.airules"
                New-AIRules -Language $lang -OutputPath $outFile 2>$null | Out-Null
                (Test-Path $outFile) | Should Be $true
            }
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
