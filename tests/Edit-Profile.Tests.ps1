BeforeAll {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $repoRoot "PowerShellDevToolkit") -Force
}

Describe "Edit-Profile" {
    It "Should be exported from the module" {
        $cmd = Get-Command Edit-Profile -ErrorAction SilentlyContinue
        ($null -ne $cmd) | Should -Be $true
    }

    It "Should create the profile file if it does not exist" {
        $fakeProfile = Join-Path $env:TEMP "pester-profile-$(Get-Random).ps1"
        $savedProfile = $PROFILE

        # Prevent the editor from actually opening during the test
        $origEditFile = $null
        try {
            Set-Variable -Name PROFILE -Value $fakeProfile -Scope Global
            # Stub Edit-File so no window opens
            function global:Edit-File { param([string]$Path) }

            Edit-Profile 2>$null
            (Test-Path $fakeProfile) | Should -Be $true
        } finally {
            Set-Variable -Name PROFILE -Value $savedProfile -Scope Global
            Remove-Item $fakeProfile -ErrorAction SilentlyContinue
            Remove-Item -Path 'function:global:Edit-File' -ErrorAction SilentlyContinue
            Import-Module (Join-Path $repoRoot "PowerShellDevToolkit") -Force
        }
    }

    It "Should not overwrite an existing profile file" {
        $fakeProfile = Join-Path $env:TEMP "pester-profile-existing-$(Get-Random).ps1"
        Set-Content $fakeProfile "# existing content"
        $savedProfile = $PROFILE
        try {
            Set-Variable -Name PROFILE -Value $fakeProfile -Scope Global
            function global:Edit-File { param([string]$Path) }

            Edit-Profile 2>$null
            $content = Get-Content $fakeProfile -Raw
            ($content -match 'existing content') | Should -Be $true
        } finally {
            Set-Variable -Name PROFILE -Value $savedProfile -Scope Global
            Remove-Item $fakeProfile -ErrorAction SilentlyContinue
            Remove-Item -Path 'function:global:Edit-File' -ErrorAction SilentlyContinue
            Import-Module (Join-Path $repoRoot "PowerShellDevToolkit") -Force
        }
    }
}
