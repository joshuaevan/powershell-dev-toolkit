$scriptDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Describe "Start-DevServer" {
    It "Should exit 1 when project type cannot be detected" {
        $dir = Join-Path $env:TEMP "pester-serve-empty-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-Location '$dir'; & '$scriptDir\Start-DevServer.ps1'" 2>$null | Out-Null
            $LASTEXITCODE | Should Be 1
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should detect Node.js project type" {
        $dir = Join-Path $env:TEMP "pester-serve-node-$(Get-Random)"
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        try {
            @{ scripts = @{ dev = "echo test" } } | ConvertTo-Json | Set-Content "$dir\package.json"
            $output = powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-Location '$dir'; & '$scriptDir\Start-DevServer.ps1' 2>&1" | Out-String
            ($output -match 'node') | Should Be $true
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
