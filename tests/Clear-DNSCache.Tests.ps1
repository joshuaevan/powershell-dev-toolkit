BeforeAll {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $repoRoot "PowerShellDevToolkit") -Force
}

Describe "Clear-DNSCache" {
    It "Should be exported from the module" {
        $cmd = Get-Command Clear-DNSCache -ErrorAction SilentlyContinue
        ($null -ne $cmd) | Should -Be $true
    }

    It "Should be accessible via the Flush-DNS alias" {
        $cmd = Get-Command Flush-DNS -ErrorAction SilentlyContinue
        ($null -ne $cmd) | Should -Be $true
    }

    It "Should either succeed or emit a helpful error message" {
        $output = Clear-DNSCache *>&1 | Out-String
        $succeeded  = $output -match 'flushed successfully'
        $failedGracefully = $output -match 'failed|administrator|admin'
        ($succeeded -or $failedGracefully) | Should -Be $true
    }

    It "Should accept no mandatory parameters" {
        $info = Get-Command Clear-DNSCache
        $required = $info.Parameters.Values | Where-Object {
            $_.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] -and $_.Mandatory }
        }
        ($required | Measure-Object).Count | Should -Be 0
    }
}
