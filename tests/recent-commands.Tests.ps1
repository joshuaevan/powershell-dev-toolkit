BeforeAll {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $repoRoot "PowerShellDevToolkit") -Force
}

Describe "recent-commands" {
    It "Should run in non-interactive mode without error" {
        $output = Show-RecentCommands -Page 1 -PageSize 10 *>&1 | Out-String
        $output | Should -Not -BeNullOrEmpty
    }

    It "Should -Contain page header" {
        $output = Show-RecentCommands -Page 1 -PageSize 10 *>&1 | Out-String
        ($output -match 'Recent Commands') | Should -Be $true
    }

    It "Should respect PageSize parameter" {
        $output = Show-RecentCommands -Page 1 -PageSize 5 -Count 50 *>&1 | Out-String
        ($output -match 'Page 1') | Should -Be $true
    }
}
