$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Import-Module (Join-Path $repoRoot "PowerShellDevToolkit") -Force

Describe "Watch-LogFile" {
    It "Should display last N lines with -NoFollow" {
        $dir = Join-Path $env:TEMP "pester-log-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            $lines = 1..50 | ForEach-Object { "Log line $_" }
            $lines | Set-Content "$dir\test.log"
            $output = Watch-LogFile -Path "$dir\test.log" -Last 5 -NoFollow *>&1 | Out-String
            ($output -match 'Log line 50') | Should Be $true
            ($output -match 'Log line 46') | Should Be $true
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should filter lines with -FilterOnly -NoFollow" {
        $dir = Join-Path $env:TEMP "pester-log-filter-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            @("INFO: all good", "ERROR: something broke", "INFO: still good", "ERROR: another failure") |
                Set-Content "$dir\test.log"
            $output = Watch-LogFile -Path "$dir\test.log" -Filter "ERROR" -FilterOnly -NoFollow -Last 100 *>&1 | Out-String
            ($output -match 'something broke') | Should Be $true
            ($output -match 'another failure') | Should Be $true
            ($output -match 'all good') | Should Be $false
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should show error for missing file" {
        $output = Watch-LogFile -Path "C:\nonexistent_log_xyz.log" -NoFollow *>&1 | Out-String
        ($output -match 'not found') | Should Be $true
    }

    It "Should show header with file path" {
        $dir = Join-Path $env:TEMP "pester-log-header-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            Set-Content "$dir\app.log" "test line"
            $output = Watch-LogFile -Path "$dir\app.log" -NoFollow *>&1 | Out-String
            ($output -match 'Tailing') | Should Be $true
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
