$scriptDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Describe "Get-ScriptConfig" {
    It "Should load config.json when present" {
        . "$scriptDir\Get-ScriptConfig.ps1"
        $config = Get-ScriptConfig
        $config | Should Not BeNullOrEmpty
    }

    It "Should have ssh section with servers" {
        . "$scriptDir\Get-ScriptConfig.ps1"
        $config = Get-ScriptConfig
        $config.ssh | Should Not BeNullOrEmpty
        $config.ssh.servers | Should Not BeNullOrEmpty
    }

    It "Should have databasePorts section" {
        . "$scriptDir\Get-ScriptConfig.ps1"
        $config = Get-ScriptConfig
        $config.ssh.databasePorts | Should Not BeNullOrEmpty
    }

    It "Should have editor section" {
        . "$scriptDir\Get-ScriptConfig.ps1"
        $config = Get-ScriptConfig
        $config.editor | Should Not BeNullOrEmpty
    }

    It "Should handle malformed JSON gracefully" {
        $tempDir = Join-Path $env:TEMP "pester-config-$(Get-Random)"
        New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
        try {
            Copy-Item "$scriptDir\Get-ScriptConfig.ps1" "$tempDir\Get-ScriptConfig.ps1"
            Set-Content "$tempDir\config.json" "NOT VALID JSON {{{{"
            $output = powershell -NoProfile -ExecutionPolicy Bypass -Command ". '$tempDir\Get-ScriptConfig.ps1'; `$r = Get-ScriptConfig 2>`$null; if (`$null -eq `$r) { 'NULL' } else { 'NOTNULL' }"
            ($output -match 'NULL') | Should Be $true
        } finally {
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
