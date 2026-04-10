BeforeAll {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $repoRoot "PowerShellDevToolkit") -Force
}

Describe "Get-DirectoryListing" {
    BeforeAll {
        function New-ListingFixture {
            $dir = Join-Path $env:TEMP "pester-ll-$(Get-Random)"
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            New-Item -Path "$dir\subdir" -ItemType Directory -Force | Out-Null
            Set-Content "$dir\file1.txt" "hello"
            Set-Content "$dir\file2.ps1" "echo hi"
            $hidden = New-Item -Path "$dir\.hidden" -ItemType File -Force
            $hidden.Attributes = 'Hidden'
            return $dir
        }
    }

    It "Should list files in the given directory" {
        $dir = New-ListingFixture
        try {
            $output = Get-DirectoryListing $dir | Out-String
            ($output -match 'file1.txt') | Should -Be $true
            ($output -match 'file2.ps1') | Should -Be $true
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should show directories in the listing" {
        $dir = New-ListingFixture
        try {
            $output = Get-DirectoryListing $dir | Out-String
            ($output -match 'subdir') | Should -Be $true
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should not show hidden files without -Force" {
        $dir = New-ListingFixture
        try {
            $output = Get-DirectoryListing $dir | Out-String
            ($output -match '\.hidden') | Should -Be $false
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should show hidden files with -Force" {
        $dir = New-ListingFixture
        try {
            $output = Get-DirectoryListing $dir -Force | Out-String
            ($output -match '\.hidden') | Should -Be $true
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should default to the current directory when no path given" {
        $dir = New-ListingFixture
        $before = Get-Location
        try {
            Set-Location $dir
            $output = Get-DirectoryListing | Out-String
            ($output -match 'file1.txt') | Should -Be $true
        } finally {
            Set-Location $before
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should be accessible via the ll alias" {
        $cmd = Get-Command ll -ErrorAction SilentlyContinue
        ($null -ne $cmd) | Should -Be $true
    }

    It "Should be accessible via the la alias and include hidden files" {
        $dir = New-ListingFixture
        $before = Get-Location
        try {
            Set-Location $dir
            $output = la | Out-String
            ($output -match '\.hidden') | Should -Be $true
        } finally {
            Set-Location $before
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
