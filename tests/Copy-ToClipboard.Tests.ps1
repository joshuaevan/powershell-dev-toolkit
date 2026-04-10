BeforeAll {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $repoRoot "PowerShellDevToolkit") -Force
}

Describe "Copy-ToClipboard" {
    It "Should copy file contents to clipboard" {
        $dir = Join-Path $env:TEMP "pester-clip-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            Set-Content "$dir\test.txt" "clipboard test content"
            Copy-ToClipboard -Path "$dir\test.txt" 2>$null | Out-Null
            $clip = Get-Clipboard
            ($clip -match 'clipboard test content') | Should -Be $true
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should copy current directory with -Pwd" {
        $before = Get-Location
        try {
            Copy-ToClipboard -Pwd 2>$null | Out-Null
            $clip = Get-Clipboard
            $clip | Should -Be (Get-Location).Path
        } finally {
            Set-Location $before
        }
    }

    It "Should copy file path with -PathOnly" {
        $dir = Join-Path $env:TEMP "pester-clip-path-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            Set-Content "$dir\test.txt" "content"
            Copy-ToClipboard -Path "$dir\test.txt" -PathOnly 2>$null | Out-Null
            $clip = Get-Clipboard
            ($clip -like "*test.txt") | Should -Be $true
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should show error for missing file" {
        $output = Copy-ToClipboard -Path "C:\nonexistent_file_xyz.txt" *>&1 | Out-String
        ($output -match 'not found') | Should -Be $true
    }

    It "Should show usage with no arguments" {
        $output = Copy-ToClipboard *>&1 | Out-String
        ($output -match 'Usage') | Should -Be $true
    }
}
