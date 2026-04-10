$scriptDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Describe "Invoke-Artisan" {
    It "Should exit 1 when no artisan file present" {
        $dir = Join-Path $env:TEMP "pester-artisan-none-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            Push-Location $dir
            & "$scriptDir\Invoke-Artisan.ps1" migrate 2>$null | Out-Null
            $LASTEXITCODE | Should Be 1
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
            $output = & "$scriptDir\Invoke-Artisan.ps1" *>&1 | Out-String
            ($output -match 'Laravel Artisan Helper') | Should Be $true
            ($output -match 'migrate') | Should Be $true
        } finally {
            Pop-Location
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
