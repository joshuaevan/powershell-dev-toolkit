BeforeAll {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    $moduleDir = Join-Path $repoRoot "PowerShellDevToolkit"
    Import-Module $moduleDir -Force

    $configPath = Join-Path $repoRoot "config.json"
    $examplePath = Join-Path $repoRoot "config.example.json"
    $script:hadConfig = Test-Path $configPath
    if (-not $script:hadConfig -and (Test-Path $examplePath)) {
        Copy-Item $examplePath $configPath
        $script:createdConfig = $true
    }
}

AfterAll {
    if ($script:createdConfig) {
        $configPath = Join-Path $repoRoot "config.json"
        Remove-Item $configPath -ErrorAction SilentlyContinue
    }
}

Describe "Get-ServiceStatus" {
    It "Should return JSON array with expected fields for git" {
        $raw = pwsh -NoProfile -Command "Import-Module '$moduleDir' -Force -DisableNameChecking; Get-ServiceStatus git -AsJson"
        $result = $raw | ConvertFrom-Json
        ($result | Measure-Object).Count | Should -BeGreaterThan 0
        $first = $result[0]
        ($null -ne $first.id) | Should -Be $true
        ($null -ne $first.name) | Should -Be $true
        ($null -ne $first.status) | Should -Be $true
    }

    It "Should report git as available" {
        $raw = pwsh -NoProfile -Command "Import-Module '$moduleDir' -Force -DisableNameChecking; Get-ServiceStatus git -AsJson"
        $result = $raw | ConvertFrom-Json
        $git = $result | Where-Object { $_.id -eq 'git' }
        $git | Should -Not -BeNullOrEmpty
        $git.status | Should -Be 'running'
    }

    It "Should handle unknown service name" {
        $raw = pwsh -NoProfile -Command "Import-Module '$moduleDir' -Force -DisableNameChecking; Get-ServiceStatus nonexistent_xyz -AsJson"
        $result = $raw | ConvertFrom-Json
        $svc = $result | Where-Object { $_.id -eq 'nonexistent_xyz' }
        $svc.status | Should -Be 'unknown'
    }

    It "Should filter to only requested services" {
        $raw = pwsh -NoProfile -Command "Import-Module '$moduleDir' -Force -DisableNameChecking; Get-ServiceStatus git node -AsJson"
        $result = $raw | ConvertFrom-Json
        ($result | Measure-Object).Count | Should -Be 2
        $ids = $result | ForEach-Object { $_.id }
        ($ids -contains 'git') | Should -Be $true
        ($ids -contains 'node') | Should -Be $true
    }
}
