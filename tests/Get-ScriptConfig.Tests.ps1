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

Describe "Get-ScriptConfig" {
    It "Should load config.json when present" {
        $config = & (Get-Module PowerShellDevToolkit) { Get-ScriptConfig }
        $config | Should -Not -BeNullOrEmpty
    }

    It "Should have ssh section with servers" {
        $config = & (Get-Module PowerShellDevToolkit) { Get-ScriptConfig }
        $config.ssh | Should -Not -BeNullOrEmpty
        $config.ssh.servers | Should -Not -BeNullOrEmpty
    }

    It "Should have databasePorts section" {
        $config = & (Get-Module PowerShellDevToolkit) { Get-ScriptConfig }
        $config.ssh.databasePorts | Should -Not -BeNullOrEmpty
    }

    It "Should have editor section" {
        $config = & (Get-Module PowerShellDevToolkit) { Get-ScriptConfig }
        $config.editor | Should -Not -BeNullOrEmpty
    }

    It "Should handle malformed JSON gracefully" {
        $tempDir = Join-Path $env:TEMP "pester-config-$(Get-Random)"
        New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
        try {
            New-Item -Path "$tempDir\PowerShellDevToolkit" -ItemType Directory -Force | Out-Null
            Copy-Item "$moduleDir\PowerShellDevToolkit.psm1" "$tempDir\PowerShellDevToolkit\"
            Copy-Item "$moduleDir\PowerShellDevToolkit.psd1" "$tempDir\PowerShellDevToolkit\"
            Copy-Item "$moduleDir\Private" "$tempDir\PowerShellDevToolkit\Private" -Recurse
            Copy-Item "$moduleDir\Public" "$tempDir\PowerShellDevToolkit\Public" -Recurse
            Set-Content "$tempDir\config.json" "NOT VALID JSON {{{{"
            $output = pwsh -NoProfile -Command "Import-Module '$tempDir\PowerShellDevToolkit' -Force; `$r = & (Get-Module PowerShellDevToolkit) { Get-ScriptConfig } 2>`$null; if (`$null -eq `$r) { 'NULL' } else { 'NOTNULL' }"
            ($output -match 'NULL') | Should -Be $true
        } finally {
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
