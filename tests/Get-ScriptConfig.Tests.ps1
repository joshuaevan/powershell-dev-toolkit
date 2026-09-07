BeforeAll {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    $moduleDir = Join-Path $repoRoot "PowerShellDevToolkit"
    Import-Module $moduleDir -Force

    $configPath = Join-Path $repoRoot "config.json"
    $examplePath = Join-Path $moduleDir "config.example.json"
    $script:hadConfig = Test-Path $configPath
    if (-not $script:hadConfig -and (Test-Path $examplePath)) {
        Copy-Item $examplePath $configPath
        $script:createdConfig = $true
    }
    $script:savedPsdtHome = $env:PSDT_HOME
}

AfterAll {
    if ($script:createdConfig) {
        $configPath = Join-Path $repoRoot "config.json"
        Remove-Item $configPath -ErrorAction SilentlyContinue
    }
    $env:PSDT_HOME = $script:savedPsdtHome
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

    Context "When config is missing or invalid" {
        BeforeEach {
            $script:tempHome = Join-Path $env:TEMP "pester-config-$(Get-Random)"
            New-Item -Path $script:tempHome -ItemType Directory -Force | Out-Null
            $env:PSDT_HOME = $script:tempHome
        }

        AfterEach {
            $env:PSDT_HOME = $script:savedPsdtHome
            Remove-Item $script:tempHome -Recurse -Force -ErrorAction SilentlyContinue
        }

        It "Should return null for malformed JSON" {
            Set-Content (Join-Path $script:tempHome "config.json") "NOT VALID JSON {{{{"
            $result = & (Get-Module PowerShellDevToolkit) { Get-ScriptConfig } 6>$null
            $result | Should -BeNullOrEmpty
        }

        It "Should tell the user where it looked and to run Initialize-Toolkit when config is missing" {
            $output = & (Get-Module PowerShellDevToolkit) { Get-ScriptConfig } *>&1 | Out-String
            $output | Should -Match 'Configuration file not found'
            $output | Should -Match ([regex]::Escape($script:tempHome))
            $output | Should -Match 'Initialize-Toolkit'
        }

        It "Should not prompt with Read-Host when config is missing" {
            Mock -ModuleName PowerShellDevToolkit Read-Host { throw "Read-Host must not be called" }
            { & (Get-Module PowerShellDevToolkit) { Get-ScriptConfig } *>&1 | Out-Null } | Should -Not -Throw
        }

        It "Should print nothing with -Quiet when config is missing" {
            $output = & (Get-Module PowerShellDevToolkit) { Get-ScriptConfig -Quiet } *>&1 | Out-String
            $output.Trim() | Should -BeNullOrEmpty
        }

        It "Should print nothing with -Quiet for malformed JSON" {
            Set-Content (Join-Path $script:tempHome "config.json") "NOT VALID JSON {{{{"
            $output = & (Get-Module PowerShellDevToolkit) { Get-ScriptConfig -Quiet } *>&1 | Out-String
            $output.Trim() | Should -BeNullOrEmpty
        }

        It "Should load config.json from PSDT_HOME" {
            Set-Content (Join-Path $script:tempHome "config.json") '{ "editor": { "notepadPlusPlus": "X:\\npp.exe" } }'
            $config = & (Get-Module PowerShellDevToolkit) { Get-ScriptConfig }
            $config.editor.notepadPlusPlus | Should -Be 'X:\npp.exe'
        }
    }
}
