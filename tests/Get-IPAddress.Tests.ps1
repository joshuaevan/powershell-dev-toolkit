BeforeAll {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $repoRoot "PowerShellDevToolkit") -Force
}

Describe "Get-IPAddress" {
    It "Should return at least one IPv4 address" {
        $result = Get-IPAddress 2>$null
        ($result | Measure-Object).Count | Should -BeGreaterThan 0
    }

    It "Should return only valid IPv4 address strings" {
        $results = Get-IPAddress 2>$null
        foreach ($addr in @($results)) {
            ($addr -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') | Should -Be $true
        }
    }

    It "Should not include APIPA link-local addresses (169.254.x.x)" {
        $results = Get-IPAddress 2>$null
        $apipa = @($results) | Where-Object { $_ -match '^169\.254\.' }
        ($apipa | Measure-Object).Count | Should -Be 0
    }

    It "Should not include the loopback address" {
        $results = Get-IPAddress 2>$null
        $loopback = @($results) | Where-Object { $_ -eq '127.0.0.1' }
        ($loopback | Measure-Object).Count | Should -Be 0
    }

    It "Should be accessible via the ip alias" {
        $cmd = Get-Command ip -ErrorAction SilentlyContinue
        ($null -ne $cmd) | Should -Be $true
    }
}
