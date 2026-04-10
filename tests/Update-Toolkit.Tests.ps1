BeforeAll {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $repoRoot "PowerShellDevToolkit") -Force -DisableNameChecking
}

Describe "Update-Toolkit" {
    It "Should be exported from the module" {
        $cmd = Get-Command Update-Toolkit -Module PowerShellDevToolkit -ErrorAction SilentlyContinue
        ($null -ne $cmd) | Should -Be $true
    }

    It "Should expose -CheckOnly and -Force parameters" {
        $info = Get-Command Update-Toolkit -Module PowerShellDevToolkit
        ($info.Parameters.ContainsKey('CheckOnly')) | Should -Be $true
        ($info.Parameters.ContainsKey('Force'))     | Should -Be $true
    }

    It "Should report status when run with -CheckOnly" {
        $output = Update-Toolkit -CheckOnly *>&1 | Out-String
        $hasStatus = ($output -match 'up to date') -or ($output -match 'available') -or ($output -match 'not a git')
        $hasStatus | Should -Be $true
    }

    It "Should show current version when up to date" {
        $output = Update-Toolkit -CheckOnly *>&1 | Out-String
        if ($output -match 'up to date') {
            ($output -match 'Version') | Should -Be $true
        }
    }
}

Describe "Test-ToolkitUpdate" {
    It "Should be exported from the module" {
        $cmd = Get-Command Test-ToolkitUpdate -Module PowerShellDevToolkit -ErrorAction SilentlyContinue
        ($null -ne $cmd) | Should -Be $true
    }

    It "Should not throw on a valid git repo" {
        { Test-ToolkitUpdate } | Should -Not -Throw
    }
}

Describe "Set-ToolkitUpdateTimestamp" {
    It "Should create the stamp file" {
        $stampFile = Join-Path $repoRoot ".last-update-check"
        if (Test-Path $stampFile) { Remove-Item $stampFile }
        & (Get-Module PowerShellDevToolkit) { Set-ToolkitUpdateTimestamp }
        (Test-Path $stampFile) | Should -Be $true
        Remove-Item $stampFile -ErrorAction SilentlyContinue
    }

    It "Should write a valid ISO 8601 timestamp" {
        & (Get-Module PowerShellDevToolkit) { Set-ToolkitUpdateTimestamp }
        $stampFile = Join-Path $repoRoot ".last-update-check"
        $content = Get-Content $stampFile -Raw
        { [datetime]::Parse($content) } | Should -Not -Throw
        Remove-Item $stampFile -ErrorAction SilentlyContinue
    }
}
