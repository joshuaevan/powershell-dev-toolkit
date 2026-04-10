BeforeAll {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $repoRoot "PowerShellDevToolkit") -Force
}

Describe "Open-Item" {
    It "Should report an error for a non-existent path" {
        $output = Open-Item "C:\this_path_does_not_exist_pester" *>&1 | Out-String
        ($output -match 'not found|cannot find|does not exist') | Should -Be $true
    }

    It "Should be accessible via the open alias" {
        $cmd = Get-Command open -ErrorAction SilentlyContinue
        ($null -ne $cmd) | Should -Be $true
    }

    It "Should be accessible via the o. function" {
        $cmd = Get-Command 'o.' -ErrorAction SilentlyContinue
        ($null -ne $cmd) | Should -Be $true
    }

    It "Should accept an explicit path parameter" {
        $info = Get-Command Open-Item
        ($info.Parameters.ContainsKey('Path')) | Should -Be $true
    }
}
