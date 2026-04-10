BeforeAll {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $repoRoot "PowerShellDevToolkit") -Force
}

Describe "Invoke-Elevated" {
    It "Should be exported from the module" {
        $cmd = Get-Command Invoke-Elevated -ErrorAction SilentlyContinue
        ($null -ne $cmd) | Should -Be $true
    }

    It "Should be accessible via the sudo alias" {
        $cmd = Get-Command sudo -ErrorAction SilentlyContinue
        ($null -ne $cmd) | Should -Be $true
    }

    It "Should expose -Command as a mandatory parameter" {
        $info = Get-Command Invoke-Elevated
        ($info.Parameters.ContainsKey('Command')) | Should -Be $true
        $attr = $info.Parameters['Command'].Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }
        $attr.Mandatory | Should -Be $true
    }

    It "Should expose an -ArgumentList parameter" {
        $info = Get-Command Invoke-Elevated
        ($info.Parameters.ContainsKey('ArgumentList')) | Should -Be $true
    }
}
