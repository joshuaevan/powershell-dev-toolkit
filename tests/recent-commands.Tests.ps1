BeforeAll {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $repoRoot "PowerShellDevToolkit") -Force
}

Describe "recent-commands" {
    It "Should run in non-interactive mode without error" {
        { Show-RecentCommands -Page 1 -PageSize 10 *>&1 | Out-Null } | Should -Not -Throw
    }

    It "Should contain page header or no-history message" {
        $output = Show-RecentCommands -Page 1 -PageSize 10 *>&1 | Out-String
        $hasHeader    = $output -match 'Recent Commands'
        $hasNoHistory = $output -match 'No commands|History file not found|Error accessing'
        $hasEmpty     = [string]::IsNullOrWhiteSpace($output)
        ($hasHeader -or $hasNoHistory -or $hasEmpty) | Should -Be $true
    }

    It "Should be accessible via the rc alias" {
        $cmd = Get-Command rc -ErrorAction SilentlyContinue
        ($null -ne $cmd) | Should -Be $true
    }
}
