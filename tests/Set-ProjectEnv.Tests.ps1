BeforeAll {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $repoRoot "PowerShellDevToolkit") -Force
}

Describe "Set-ProjectEnv" {
    It "Should load .env variables into process environment" {
        $dir = Join-Path $env:TEMP "pester-env-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            Set-Content "$dir\.env" "PESTER_TEST_VAR=hello123`nPESTER_TEST_VAR2=world456"
            Push-Location $dir
            Set-ProjectEnv -Path "$dir\.env" 2>$null | Out-Null
            Pop-Location
            [Environment]::GetEnvironmentVariable('PESTER_TEST_VAR') | Should -Be 'hello123'
            [Environment]::GetEnvironmentVariable('PESTER_TEST_VAR2') | Should -Be 'world456'
        } finally {
            [Environment]::SetEnvironmentVariable('PESTER_TEST_VAR', $null, 'Process')
            [Environment]::SetEnvironmentVariable('PESTER_TEST_VAR2', $null, 'Process')
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should parse quoted values" {
        $dir = Join-Path $env:TEMP "pester-env-quoted-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            Set-Content "$dir\.env" 'PESTER_QUOTED="value with spaces"'
            Set-ProjectEnv -Path "$dir\.env" 2>$null | Out-Null
            [Environment]::GetEnvironmentVariable('PESTER_QUOTED') | Should -Be 'value with spaces'
        } finally {
            [Environment]::SetEnvironmentVariable('PESTER_QUOTED', $null, 'Process')
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should skip comments and empty lines" {
        $dir = Join-Path $env:TEMP "pester-env-comments-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            $content = "# This is a comment`n`nPESTER_REAL_VAR=yes`n# Another comment`n"
            Set-Content "$dir\.env" $content
            Set-ProjectEnv -Path "$dir\.env" 2>$null | Out-Null
            [Environment]::GetEnvironmentVariable('PESTER_REAL_VAR') | Should -Be 'yes'
        } finally {
            [Environment]::SetEnvironmentVariable('PESTER_REAL_VAR', $null, 'Process')
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should handle inline comments for unquoted values" {
        $dir = Join-Path $env:TEMP "pester-env-inline-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            Set-Content "$dir\.env" "PESTER_INLINE=value # this is a comment"
            Set-ProjectEnv -Path "$dir\.env" 2>$null | Out-Null
            [Environment]::GetEnvironmentVariable('PESTER_INLINE') | Should -Be 'value'
        } finally {
            [Environment]::SetEnvironmentVariable('PESTER_INLINE', $null, 'Process')
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should show error for missing .env file" {
        $dir = Join-Path $env:TEMP "pester-env-missing-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            $output = Set-ProjectEnv -Path "$dir\.env.nonexistent" *>&1 | Out-String
            ($output -match 'not found') | Should -Be $true
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should list variables with -List without setting them" {
        $dir = Join-Path $env:TEMP "pester-env-list-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            Set-Content "$dir\.env" "LIST_ONLY_VAR=should_not_set"
            Set-ProjectEnv -Path "$dir\.env" -List 2>$null | Out-Null
            [Environment]::GetEnvironmentVariable('LIST_ONLY_VAR') | Should -BeNullOrEmpty
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
