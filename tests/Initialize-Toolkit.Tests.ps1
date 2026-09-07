BeforeAll {
    $repoRoot  = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    $moduleDir = Join-Path $repoRoot "PowerShellDevToolkit"
    Import-Module $moduleDir -Force -DisableNameChecking
    $script:savedPsdtHome = $env:PSDT_HOME
    $script:examplePath = Join-Path $moduleDir "config.example.json"
}

AfterAll {
    $env:PSDT_HOME = $script:savedPsdtHome
}

Describe "Initialize-Toolkit" {
    BeforeEach {
        $script:tkHome = Join-Path $env:TEMP "pester-init-$(Get-Random)"
        $env:PSDT_HOME = $script:tkHome
        $script:configPath = Join-Path $script:tkHome "config.json"
        Mock -ModuleName PowerShellDevToolkit Edit-File { }
    }

    AfterEach {
        Remove-Item $script:tkHome -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "Should be exported from the module" {
        (Get-Command Initialize-Toolkit -Module PowerShellDevToolkit -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
    }

    It "Should create the data folder, creds folder and config.json" {
        Initialize-Toolkit -NoOpen *>&1 | Out-Null
        Test-Path $script:tkHome                       | Should -Be $true
        Test-Path (Join-Path $script:tkHome 'creds')   | Should -Be $true
        Test-Path $script:configPath                   | Should -Be $true
    }

    It "Should create a config identical to the example" {
        Initialize-Toolkit -NoOpen *>&1 | Out-Null
        (Get-Content $script:configPath -Raw) | Should -Be (Get-Content $script:examplePath -Raw)
    }

    It "Should leave an existing config alone without -Force" {
        New-Item -Path $script:tkHome -ItemType Directory -Force | Out-Null
        Set-Content $script:configPath '{ "custom": true }'
        $output = Initialize-Toolkit -NoOpen *>&1 | Out-String
        (Get-Content $script:configPath -Raw) | Should -Match 'custom'
        $output | Should -Match 'already exists'
    }

    It "Should replace an existing config with -Force" {
        New-Item -Path $script:tkHome -ItemType Directory -Force | Out-Null
        Set-Content $script:configPath '{ "custom": true }'
        Initialize-Toolkit -NoOpen -Force *>&1 | Out-Null
        (Get-Content $script:configPath -Raw) | Should -Not -Match 'custom'
        (Get-Content $script:configPath -Raw) | Should -Match '"ssh"'
    }

    It "Should report the resolved paths and next steps" {
        $output = Initialize-Toolkit -NoOpen *>&1 | Out-String
        $output | Should -Match ([regex]::Escape($script:tkHome))
        $output | Should -Match 'Git'
        $output | Should -Match 'New-SSHCredential'
    }

    It "Should not open an editor with -NoOpen" {
        Initialize-Toolkit -NoOpen *>&1 | Out-Null
        Should -Invoke -ModuleName PowerShellDevToolkit Edit-File -Times 0 -Exactly
    }

    It "Should open the config in the editor by default" {
        Initialize-Toolkit *>&1 | Out-Null
        Should -Invoke -ModuleName PowerShellDevToolkit Edit-File -Times 1 -Exactly
    }

    It "Should not prompt with Read-Host" {
        Mock -ModuleName PowerShellDevToolkit Read-Host { throw "Read-Host must not be called" }
        { Initialize-Toolkit -NoOpen *>&1 | Out-Null } | Should -Not -Throw
    }
}
