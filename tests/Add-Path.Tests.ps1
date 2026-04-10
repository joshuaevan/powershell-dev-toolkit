BeforeAll {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $repoRoot "PowerShellDevToolkit") -Force
}

Describe "Add-Path" {
    It "Should add a new directory to the user PATH" {
        $fakeDir = Join-Path $env:TEMP "pester-addpath-$(Get-Random)"
        New-Item -Path $fakeDir -ItemType Directory -Force | Out-Null
        $originalUserPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
        try {
            Add-Path $fakeDir -User 2>$null
            $newUserPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
            ($newUserPath -split ';' -contains $fakeDir) | Should -Be $true
        } finally {
            [System.Environment]::SetEnvironmentVariable('Path', $originalUserPath, 'User')
            Remove-Item $fakeDir -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should add the directory to the current session PATH" {
        $fakeDir = Join-Path $env:TEMP "pester-addpath-session-$(Get-Random)"
        New-Item -Path $fakeDir -ItemType Directory -Force | Out-Null
        $originalUserPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
        $originalEnvPath = $env:Path
        try {
            Add-Path $fakeDir -User 2>$null
            ($env:Path -split ';' -contains $fakeDir) | Should -Be $true
        } finally {
            $env:Path = $originalEnvPath
            [System.Environment]::SetEnvironmentVariable('Path', $originalUserPath, 'User')
            Remove-Item $fakeDir -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should skip silently when the directory is already in PATH" {
        $fakeDir = Join-Path $env:TEMP "pester-addpath-dupe-$(Get-Random)"
        New-Item -Path $fakeDir -ItemType Directory -Force | Out-Null
        $originalUserPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
        try {
            Add-Path $fakeDir -User 2>$null
            $output = Add-Path $fakeDir -User *>&1 | Out-String
            ($output -match 'Already in') | Should -Be $true
        } finally {
            [System.Environment]::SetEnvironmentVariable('Path', $originalUserPath, 'User')
            Remove-Item $fakeDir -Force -ErrorAction SilentlyContinue
        }
    }
}
