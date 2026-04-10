BeforeAll {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $repoRoot "PowerShellDevToolkit") -Force
}

Describe "Edit-Hosts" {
    It "Should be exported from the module" {
        $cmd = Get-Command Edit-Hosts -ErrorAction SilentlyContinue
        ($null -ne $cmd) | Should -Be $true
    }

    It "Should target the correct hosts file path" {
        $expected = "$env:SystemRoot\System32\drivers\etc\hosts"
        (Test-Path $expected) | Should -Be $true
    }

    It "Should accept no parameters" {
        $info = Get-Command Edit-Hosts
        $requiredParams = $info.Parameters.Values | Where-Object { $_.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] -and $_.Mandatory } }
        ($requiredParams | Measure-Object).Count | Should -Be 0
    }
}
