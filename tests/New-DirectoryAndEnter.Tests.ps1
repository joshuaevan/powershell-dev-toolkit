BeforeAll {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $repoRoot "PowerShellDevToolkit") -Force
}

Describe "New-DirectoryAndEnter" {
    It "Should create the directory" {
        $parent = Join-Path $env:TEMP "pester-mkcd-$(Get-Random)"
        $target = Join-Path $parent "newdir"
        $before = Get-Location
        try {
            New-DirectoryAndEnter $target
            (Test-Path $target) | Should -Be $true
        } finally {
            Set-Location $before
            Remove-Item $parent -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should navigate into the created directory" {
        $parent = Join-Path $env:TEMP "pester-mkcd-$(Get-Random)"
        $target = Join-Path $parent "newdir"
        $before = Get-Location
        try {
            New-DirectoryAndEnter $target
            (Get-Item (Get-Location).Path).FullName | Should -Be (Get-Item $target).FullName
        } finally {
            Set-Location $before
            Remove-Item $parent -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should create nested directories in one call" {
        $parent = Join-Path $env:TEMP "pester-mkcd-$(Get-Random)"
        $target = Join-Path $parent "a\b\c"
        $before = Get-Location
        try {
            New-DirectoryAndEnter $target
            (Test-Path $target) | Should -Be $true
            (Get-Item (Get-Location).Path).FullName | Should -Be (Get-Item $target).FullName
        } finally {
            Set-Location $before
            Remove-Item $parent -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should be accessible via the mkcd alias" {
        $cmd = Get-Command mkcd -ErrorAction SilentlyContinue
        ($null -ne $cmd) | Should -Be $true
    }
}
