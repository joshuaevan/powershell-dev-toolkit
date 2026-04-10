BeforeAll {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $repoRoot "PowerShellDevToolkit") -Force
}

Describe "Edit-File" {
    It "Should be exported from the module" {
        $cmd = Get-Command Edit-File -ErrorAction SilentlyContinue
        ($null -ne $cmd) | Should -Be $true
    }

    It "Should be accessible via the e alias" {
        $cmd = Get-Command e -ErrorAction SilentlyContinue
        ($null -ne $cmd) | Should -Be $true
    }

    It "Should be accessible via the npp alias" {
        $cmd = Get-Command npp -ErrorAction SilentlyContinue
        ($null -ne $cmd) | Should -Be $true
    }

    It "Should report an error for a non-existent path" {
        $output = Edit-File "C:\this_path_does_not_exist_pester_xyz" *>&1 | Out-String
        ($output -match 'not found|cannot find|does not exist') | Should -Be $true
    }

    It "Should expose -Path, -Line, and -Column parameters" {
        $info = Get-Command Edit-File
        ($info.Parameters.ContainsKey('Path'))   | Should -Be $true
        ($info.Parameters.ContainsKey('Line'))   | Should -Be $true
        ($info.Parameters.ContainsKey('Column')) | Should -Be $true
    }
}
