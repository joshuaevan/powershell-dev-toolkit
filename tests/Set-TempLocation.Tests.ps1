BeforeAll {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $repoRoot "PowerShellDevToolkit") -Force
}

Describe "Set-TempLocation" {
    It "Should navigate to the Windows temp directory" {
        $before = Get-Location
        try {
            Set-TempLocation
            $actual = (Get-Item (Get-Location).Path).FullName
            $expected = (Get-Item $env:TEMP).FullName
            $actual | Should -Be $expected
        } finally {
            Set-Location $before
        }
    }

    It "Should be accessible via the temp alias" {
        $cmd = Get-Command temp -ErrorAction SilentlyContinue
        ($null -ne $cmd) | Should -Be $true
    }

    It "Should result in a location that exists" {
        $before = Get-Location
        try {
            Set-TempLocation
            (Test-Path (Get-Location).Path) | Should -Be $true
        } finally {
            Set-Location $before
        }
    }
}
