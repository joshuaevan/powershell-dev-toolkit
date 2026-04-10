BeforeAll {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $repoRoot "PowerShellDevToolkit") -Force
}

Describe "Get-GitQuick" {
    BeforeAll {
        function New-TempGitRepo {
            $dir = Join-Path $env:TEMP "pester-git-$(Get-Random)"
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Push-Location $dir
            git init . 2>$null | Out-Null
            git config user.email "test@test.com" 2>$null
            git config user.name "Test" 2>$null
            git commit --allow-empty -m "init" 2>$null | Out-Null
            Pop-Location
            return $dir
        }
    }
    It "Should return correct JSON schema for clean repo" {
        $tempDir = New-TempGitRepo
        Push-Location $tempDir
        try {
            $raw = Get-GitQuick -AsJson 2>$null
            $result = $raw | ConvertFrom-Json
            ($null -ne $result.branch) | Should -Be $true
            ($null -ne $result.ahead) | Should -Be $true
            ($null -ne $result.behind) | Should -Be $true
            ($null -ne $result.staged) | Should -Be $true
            ($null -ne $result.modified) | Should -Be $true
            ($null -ne $result.untracked) | Should -Be $true
            ($null -ne $result.clean) | Should -Be $true
            ($null -ne $result.files) | Should -Be $true
        } finally {
            Pop-Location
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should report clean = true on clean repo" {
        $tempDir = New-TempGitRepo
        Push-Location $tempDir
        try {
            $raw = Get-GitQuick -AsJson 2>$null
            $result = $raw | ConvertFrom-Json
            $result.clean | Should -Be $true
            $result.staged | Should -Be 0
            $result.modified | Should -Be 0
            $result.untracked | Should -Be 0
        } finally {
            Pop-Location
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should detect untracked files" {
        $tempDir = New-TempGitRepo
        Push-Location $tempDir
        try {
            Set-Content "newfile.txt" "hello"
            $raw = Get-GitQuick -AsJson 2>$null
            $result = $raw | ConvertFrom-Json
            $result.clean | Should -Be $false
            $result.untracked | Should -Be 1
        } finally {
            Pop-Location
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should detect staged files" {
        $tempDir = New-TempGitRepo
        Push-Location $tempDir
        try {
            Set-Content "staged.txt" "content"
            git add staged.txt 2>$null
            $raw = Get-GitQuick -AsJson 2>$null
            $result = $raw | ConvertFrom-Json
            $result.staged | Should -Be 1
            $result.clean | Should -Be $false
        } finally {
            Pop-Location
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should detect modified files" {
        $tempDir = New-TempGitRepo
        Push-Location $tempDir
        try {
            Set-Content "tracked.txt" "original"
            git add tracked.txt 2>$null
            git commit -m "add tracked" 2>$null | Out-Null
            Set-Content "tracked.txt" "modified"
            $raw = Get-GitQuick -AsJson 2>$null
            $result = $raw | ConvertFrom-Json
            $result.modified | Should -Be 1
        } finally {
            Pop-Location
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should report correct branch name" {
        $tempDir = New-TempGitRepo
        Push-Location $tempDir
        try {
            $raw = Get-GitQuick -AsJson 2>$null
            $result = $raw | ConvertFrom-Json
            ($result.branch -eq 'main' -or $result.branch -eq 'master') | Should -Be $true
        } finally {
            Pop-Location
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should report stash count" {
        $tempDir = New-TempGitRepo
        Push-Location $tempDir
        try {
            $raw = Get-GitQuick -AsJson 2>$null
            $result = $raw | ConvertFrom-Json
            $result.stashes | Should -Be 0
        } finally {
            Pop-Location
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should have files object with sub-arrays" {
        $tempDir = New-TempGitRepo
        Push-Location $tempDir
        try {
            $raw = Get-GitQuick -AsJson 2>$null
            $result = $raw | ConvertFrom-Json
            ($null -ne $result.files.staged) | Should -Be $true
            ($null -ne $result.files.modified) | Should -Be $true
            ($null -ne $result.files.deleted) | Should -Be $true
            ($null -ne $result.files.untracked) | Should -Be $true
            ($null -ne $result.files.conflicts) | Should -Be $true
        } finally {
            Pop-Location
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
