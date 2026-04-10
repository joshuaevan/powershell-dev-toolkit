$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Import-Module (Join-Path $repoRoot "PowerShellDevToolkit") -Force

Describe "Invoke-Artisan" {
    It "Should show error when no artisan file present" {
        $dir = Join-Path $env:TEMP "pester-artisan-none-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            Push-Location $dir
            $output = Invoke-Artisan migrate *>&1 | Out-String
            ($output -match 'Not a Laravel project') | Should Be $true
        } finally {
            Pop-Location
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should show help when artisan exists but no command given" {
        $dir = Join-Path $env:TEMP "pester-artisan-help-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            Set-Content "$dir\artisan" "#!/usr/bin/env php"
            Push-Location $dir
            $output = Invoke-Artisan *>&1 | Out-String
            ($output -match 'Laravel Artisan Helper') | Should Be $true
            ($output -match 'migrate') | Should Be $true
        } finally {
            Pop-Location
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
