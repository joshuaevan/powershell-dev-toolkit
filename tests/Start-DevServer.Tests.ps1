BeforeAll {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    $moduleDir = Join-Path $repoRoot "PowerShellDevToolkit"
    Import-Module $moduleDir -Force
}

Describe "Start-DevServer" {
    It "Should show error when project type cannot be detected" {
        $dir = Join-Path $env:TEMP "pester-serve-empty-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            $output = powershell -NoProfile -ExecutionPolicy Bypass -Command "Import-Module '$moduleDir' -Force; Set-Location '$dir'; Start-DevServer 2>&1" | Out-String
            ($output -match 'Could not detect') | Should -Be $true
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should detect Node.js project type" {
        $dir = Join-Path $env:TEMP "pester-serve-node-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            @{ scripts = @{ dev = "echo test" } } | ConvertTo-Json | Set-Content "$dir\package.json"
            $output = powershell -NoProfile -ExecutionPolicy Bypass -Command "Import-Module '$moduleDir' -Force; Set-Location '$dir'; Start-DevServer 2>&1" | Out-String
            ($output -match 'node') | Should -Be $true
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
