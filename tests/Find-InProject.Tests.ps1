BeforeAll {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $repoRoot "PowerShellDevToolkit") -Force
}

Describe "Find-InProject" {
    BeforeAll {
        function New-SearchFixture {
        $dir = Join-Path $env:TEMP "pester-search-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        Set-Content "$dir\app.php" "<?php`nfunction login() {`n    return true;`n}`n"
        Set-Content "$dir\utils.js" "export function login() {`n    return false;`n}`n"
        Set-Content "$dir\readme.txt" "This is a readme file with no matches."
        New-Item -Path "$dir\node_modules" -ItemType Directory -Force | Out-Null
        Set-Content "$dir\node_modules\dep.js" "function login() { }`n"
        New-Item -Path "$dir\vendor" -ItemType Directory -Force | Out-Null
        Set-Content "$dir\vendor\lib.php" "function login() { }`n"
            return $dir
        }
    }

    It "Should find matches and return correct JSON structure" {
        $tempDir = New-SearchFixture
        try {
            $raw = Find-InProject -Pattern "login" -Path $tempDir -AsJson 2>$null
            $result = $raw | ConvertFrom-Json
            $result.pattern | Should -Be "login"
            $result.totalMatches | Should -BeGreaterThan 0
            $result.fileCount | Should -BeGreaterThan 0
            ($result.results | Measure-Object).Count | Should -BeGreaterThan 0
        } finally {
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should return match line numbers" {
        $tempDir = New-SearchFixture
        try {
            $raw = Find-InProject -Pattern "login" -Path $tempDir -AsJson 2>$null
            $result = $raw | ConvertFrom-Json
            $firstMatch = $result.results[0].matches[0]
            $firstMatch.line | Should -BeGreaterThan 0
            $firstMatch.content | Should -Not -BeNullOrEmpty
        } finally {
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should respect -Type filter for php" {
        $tempDir = New-SearchFixture
        try {
            $raw = Find-InProject "login" -Type "php" -Path $tempDir -AsJson 2>$null
            $result = $raw | ConvertFrom-Json
            $result.fileCount | Should -Be 1
            $files = $result.results | ForEach-Object { $_.file }
            ($files | Where-Object { $_ -like "*.php" } | Measure-Object).Count | Should -Be 1
        } finally {
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should exclude node_modules and vendor directories" {
        $tempDir = New-SearchFixture
        try {
            $raw = Find-InProject -Pattern "login" -Path $tempDir -AsJson 2>$null
            $result = $raw | ConvertFrom-Json
            $files = $result.results | ForEach-Object { $_.file }
            $hasNodeModules = ($files | Where-Object { $_ -match 'node_modules' } | Measure-Object).Count
            $hasVendor = ($files | Where-Object { $_ -match 'vendor' } | Measure-Object).Count
            $hasNodeModules | Should -Be 0
            $hasVendor | Should -Be 0
        } finally {
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should be case-insensitive by default" {
        $tempDir = New-SearchFixture
        try {
            $raw = Find-InProject -Pattern "LOGIN" -Path $tempDir -AsJson 2>$null
            $result = $raw | ConvertFrom-Json
            $result.totalMatches | Should -BeGreaterThan 0
        } finally {
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should respect -CaseSensitive flag" {
        $tempDir = New-SearchFixture
        try {
            $raw = Find-InProject -Pattern "LOGIN" -CaseSensitive -Path $tempDir -AsJson 2>$null
            $result = $raw | ConvertFrom-Json
            $result.totalMatches | Should -Be 0
        } finally {
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should return zero matches for non-matching pattern" {
        $tempDir = New-SearchFixture
        try {
            $raw = Find-InProject -Pattern "zzz_no_match_zzz" -Path $tempDir -AsJson 2>$null
            $result = $raw | ConvertFrom-Json
            $result.totalMatches | Should -Be 0
            $result.fileCount | Should -Be 0
        } finally {
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should find matches in both php and js files" {
        $tempDir = New-SearchFixture
        try {
            $raw = Find-InProject -Pattern "login" -Path $tempDir -AsJson 2>$null
            $result = $raw | ConvertFrom-Json
            $result.fileCount | Should -Be 2
        } finally {
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
