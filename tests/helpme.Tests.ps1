BeforeAll {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $repoRoot "PowerShellDevToolkit") -Force
}

Describe "helpme" {
    It "Should run without error" {
        $output = Show-Help *>&1 | Out-String
        $output | Should -Not -BeNullOrEmpty
    }

    It "Should -Contain SSH command references" {
        $output = Show-Help *>&1 | Out-String
        ($output -match 'cssh') | Should -Be $true
        ($output -match 'tunnel') | Should -Be $true
    }

    It "Should -Contain development command references" {
        $output = Show-Help *>&1 | Out-String
        ($output -match 'gs') | Should -Be $true
        ($output -match 'serve') | Should -Be $true
        ($output -match 'port') | Should -Be $true
        ($output -match 'search') | Should -Be $true
    }

    It "Should -Contain utility command references" {
        $output = Show-Help *>&1 | Out-String
        ($output -match 'reload') | Should -Be $true
        ($output -match 'recent-commands') | Should -Be $true
    }

    It "Should -Contain AI integration section" {
        $output = Show-Help *>&1 | Out-String
        ($output -match 'ai-rules') | Should -Be $true
        ($output -match 'context') | Should -Be $true
    }
}
