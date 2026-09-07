BeforeAll {
    $repoRoot  = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    $moduleDir = Join-Path $repoRoot "PowerShellDevToolkit"
    Import-Module $moduleDir -Force -DisableNameChecking
    $script:savedPsdtHome = $env:PSDT_HOME
}

AfterAll {
    $env:PSDT_HOME = $script:savedPsdtHome
}

Describe "Connect-SSH and Connect-SSHTunnel without config" {
    BeforeEach {
        $script:tkHome = Join-Path $env:TEMP "pester-ssh-noconfig-$(Get-Random)"
        New-Item -Path $script:tkHome -ItemType Directory -Force | Out-Null
        $env:PSDT_HOME = $script:tkHome
    }

    AfterEach {
        Remove-Item $script:tkHome -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "Connect-SSH tells the user to configure and does not try to connect" {
        Mock -ModuleName PowerShellDevToolkit Test-WslAvailable { throw "must not probe WSL without config" }
        $output = Connect-SSH myserver *>&1 | Out-String
        $output | Should -Match 'Initialize-Toolkit'
        $output | Should -Match 'configure config.json'
    }

    It "Connect-SSHTunnel tells the user to configure and does not try to connect" {
        Mock -ModuleName PowerShellDevToolkit Test-WslAvailable { throw "must not probe WSL without config" }
        $output = Connect-SSHTunnel myserver postgres *>&1 | Out-String
        $output | Should -Match 'Initialize-Toolkit'
        $output | Should -Match 'configure config.json'
    }
}

Describe "Connect-SSH with config but missing credential file" {
    BeforeEach {
        $script:tkHome = Join-Path $env:TEMP "pester-ssh-nocred-$(Get-Random)"
        New-Item -Path $script:tkHome -ItemType Directory -Force | Out-Null
        $env:PSDT_HOME = $script:tkHome
        Set-Content (Join-Path $script:tkHome 'config.json') '{ "ssh": { "servers": { "box": { "hostname": "box.example.com" } } } }'
        Mock -ModuleName PowerShellDevToolkit Test-WslAvailable { $true }
    }

    AfterEach {
        Remove-Item $script:tkHome -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "Stops with the credential-file message before any connection attempt" {
        $output = Connect-SSH box *>&1 | Out-String
        $output | Should -Match 'Credential file not found'
        $output | Should -Match ([regex]::Escape((Join-Path $script:tkHome 'creds')))
    }

    It "Tunnel stops with the credential-file message before any connection attempt" {
        $output = Connect-SSHTunnel box 5432 *>&1 | Out-String
        $output | Should -Match 'Credential file not found'
    }
}
