BeforeAll {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $repoRoot "PowerShellDevToolkit") -Force
}

Describe "Set-FileTimestamp" {
    It "Should create a new file when it does not exist" {
        $dir = Join-Path $env:TEMP "pester-touch-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            $file = Join-Path $dir "newfile.txt"
            Set-FileTimestamp $file
            (Test-Path $file) | Should -Be $true
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should update LastWriteTime on an existing file" {
        $dir = Join-Path $env:TEMP "pester-touch-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            $file = Join-Path $dir "existing.txt"
            Set-Content $file "hello"
            $before = (Get-Item $file).LastWriteTime
            Start-Sleep -Milliseconds 100
            Set-FileTimestamp $file
            $after = (Get-Item $file).LastWriteTime
            ($after -gt $before) | Should -Be $true
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should create missing parent directories" {
        $dir = Join-Path $env:TEMP "pester-touch-$(Get-Random)"
        try {
            $file = Join-Path $dir "subdir\deep\newfile.txt"
            Set-FileTimestamp $file
            (Test-Path $file) | Should -Be $true
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should be accessible via the touch alias" {
        $cmd = Get-Command touch -ErrorAction SilentlyContinue
        ($null -ne $cmd) | Should -Be $true
    }

    It "Should accept pipeline input" {
        $dir = Join-Path $env:TEMP "pester-touch-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            $file = Join-Path $dir "piped.txt"
            $file | Set-FileTimestamp
            (Test-Path $file) | Should -Be $true
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
