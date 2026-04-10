$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$moduleDir = Join-Path $repoRoot "PowerShellDevToolkit"
Import-Module $moduleDir -Force

Describe "Get-ScriptConfig" {
    It "Should load config.json when present" {
        $config = Get-ScriptConfig
        $config | Should Not BeNullOrEmpty
    }

    It "Should have ssh section with servers" {
        $config = Get-ScriptConfig
        $config.ssh | Should Not BeNullOrEmpty
        $config.ssh.servers | Should Not BeNullOrEmpty
    }

    It "Should have databasePorts section" {
        $config = Get-ScriptConfig
        $config.ssh.databasePorts | Should Not BeNullOrEmpty
    }

    It "Should have editor section" {
        $config = Get-ScriptConfig
        $config.editor | Should Not BeNullOrEmpty
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
            $output = powershell -NoProfile -ExecutionPolicy Bypass -Command "Import-Module '$tempDir\PowerShellDevToolkit' -Force; `$r = Get-ScriptConfig 2>`$null; if (`$null -eq `$r) { 'NULL' } else { 'NOTNULL' }"
            ($output -match 'NULL') | Should Be $true
        } finally {
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
