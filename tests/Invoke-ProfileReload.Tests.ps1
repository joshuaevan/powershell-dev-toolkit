BeforeAll {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $repoRoot "PowerShellDevToolkit") -Force
}

Describe "Invoke-ProfileReload" {
    It "Should be accessible via the reload alias" {
        $cmd = Get-Command reload -ErrorAction SilentlyContinue
        ($null -ne $cmd) | Should -Be $true
    }

    It "Should warn when no profile file exists" {
        $fakeProfile = Join-Path $env:TEMP "pester-profile-missing-$(Get-Random).ps1"
        $savedProfile = $PROFILE
        try {
            Set-Variable -Name PROFILE -Value $fakeProfile -Scope Global
            $output = Invoke-ProfileReload *>&1 | Out-String
            ($output -match 'No profile|not found') | Should -Be $true
        } finally {
            Set-Variable -Name PROFILE -Value $savedProfile -Scope Global
        }
    }

    It "Should dot-source the profile and apply its definitions" {
        $dir = Join-Path $env:TEMP "pester-reload-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        $fakeProfile = Join-Path $dir "profile.ps1"
        Set-Content $fakeProfile 'function global:PesterTestReloadMarker { "reloaded" }'
        $savedProfile = $PROFILE
        try {
            Set-Variable -Name PROFILE -Value $fakeProfile -Scope Global
            Invoke-ProfileReload 2>$null
            $result = PesterTestReloadMarker
            $result | Should -Be 'reloaded'
        } finally {
            Set-Variable -Name PROFILE -Value $savedProfile -Scope Global
            Remove-Item -Path 'function:global:PesterTestReloadMarker' -ErrorAction SilentlyContinue
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
