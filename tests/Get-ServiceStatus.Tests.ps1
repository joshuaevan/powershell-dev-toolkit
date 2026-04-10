$scriptDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Describe "Get-ServiceStatus" {
    It "Should return JSON array with expected fields for git" {
        $raw = powershell -NoProfile -ExecutionPolicy Bypass -Command "& '$scriptDir\Get-ServiceStatus.ps1' git -AsJson"
        $result = $raw | ConvertFrom-Json
        ($result | Measure-Object).Count | Should BeGreaterThan 0
        $first = $result[0]
        ($null -ne $first.id) | Should Be $true
        ($null -ne $first.name) | Should Be $true
        ($null -ne $first.status) | Should Be $true
    }

    It "Should report git as available" {
        $raw = powershell -NoProfile -ExecutionPolicy Bypass -Command "& '$scriptDir\Get-ServiceStatus.ps1' git -AsJson"
        $result = $raw | ConvertFrom-Json
        $git = $result | Where-Object { $_.id -eq 'git' }
        $git | Should Not BeNullOrEmpty
        $git.status | Should Be 'running'
    }

    It "Should handle unknown service name" {
        $raw = powershell -NoProfile -ExecutionPolicy Bypass -Command "& '$scriptDir\Get-ServiceStatus.ps1' nonexistent_xyz -AsJson"
        $result = $raw | ConvertFrom-Json
        $svc = $result | Where-Object { $_.id -eq 'nonexistent_xyz' }
        $svc.status | Should Be 'unknown'
    }

    It "Should filter to only requested services" {
        $raw = powershell -NoProfile -ExecutionPolicy Bypass -Command "& '$scriptDir\Get-ServiceStatus.ps1' git node -AsJson"
        $result = $raw | ConvertFrom-Json
        ($result | Measure-Object).Count | Should Be 2
        $ids = $result | ForEach-Object { $_.id }
        ($ids -contains 'git') | Should Be $true
        ($ids -contains 'node') | Should Be $true
    }
}
