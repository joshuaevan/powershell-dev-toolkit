BeforeAll {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $repoRoot "PowerShellDevToolkit") -Force
}

Describe "Get-CommandLocation" {
    It "Should return a path for a known command" {
        $result = Get-CommandLocation pwsh 2>$null
        ($result | Should -Not -BeNullOrEmpty) | Out-Null
        (Test-Path $result) | Should -Be $true
    }

    It "Should find git when it is installed" {
        $git = Get-Command git -ErrorAction SilentlyContinue
        if (-not $git) {
            Write-Host "  Skipping: git not installed." -ForegroundColor Yellow
            return
        }
        $result = Get-CommandLocation git 2>$null
        $result | Should -Not -BeNullOrEmpty
    }

    It "Should emit a warning for an unknown command" {
        $output = Get-CommandLocation "zzz_no_such_cmd_pester_xyz" *>&1 | Out-String
        ($output -match 'command not found|not found') | Should -Be $true
    }

    It "Should return nothing (not throw) for an unknown command" {
        $result = Get-CommandLocation "zzz_no_such_cmd_pester_xyz" 2>$null
        ($null -eq $result) | Should -Be $true
    }

    It "Should be accessible via the which alias" {
        $cmd = Get-Command which -ErrorAction SilentlyContinue
        ($null -ne $cmd) | Should -Be $true
    }

    It "Should expose a -All switch parameter" {
        $info = Get-Command Get-CommandLocation
        ($info.Parameters.ContainsKey('All')) | Should -Be $true
    }
}
