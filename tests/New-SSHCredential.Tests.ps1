BeforeAll {
    $repoRoot  = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    $moduleDir = Join-Path $repoRoot "PowerShellDevToolkit"
    Import-Module $moduleDir -Force -DisableNameChecking
    $script:savedPsdtHome = $env:PSDT_HOME

    function New-TestCredential {
        param([string]$User, [string]$Password)
        New-Object System.Management.Automation.PSCredential($User, (ConvertTo-SecureString $Password -AsPlainText -Force))
    }
}

AfterAll {
    $env:PSDT_HOME = $script:savedPsdtHome
}

Describe "New-SSHCredential" {
    BeforeEach {
        $script:tkHome = Join-Path $env:TEMP "pester-sshcred-$(Get-Random)"
        New-Item -Path $script:tkHome -ItemType Directory -Force | Out-Null
        $env:PSDT_HOME = $script:tkHome
        $script:cred = New-TestCredential -User 'deploy' -Password 'p@ss w0rd'
        $script:defaultFile = Join-Path $script:tkHome 'creds\ssh-credentials.xml'
    }

    AfterEach {
        Remove-Item $script:tkHome -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "Should be exported from the module" {
        (Get-Command New-SSHCredential -Module PowerShellDevToolkit -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
    }

    It "Should write a credential file that round-trips through Import-Clixml" {
        New-SSHCredential -Credential $script:cred *>&1 | Out-Null
        Test-Path $script:defaultFile | Should -Be $true
        $loaded = Import-Clixml $script:defaultFile
        $loaded.UserName | Should -Be 'deploy'
        $loaded.GetNetworkCredential().Password | Should -Be 'p@ss w0rd'
    }

    It "Should create the creds folder when it does not exist" {
        Test-Path (Join-Path $script:tkHome 'creds') | Should -Be $false
        New-SSHCredential -Credential $script:cred *>&1 | Out-Null
        Test-Path (Join-Path $script:tkHome 'creds') | Should -Be $true
    }

    It "Should use ssh.credentialFile from config.json as the default file name" {
        Set-Content (Join-Path $script:tkHome 'config.json') '{ "ssh": { "credentialFile": "custom-creds.xml" } }'
        New-SSHCredential -Credential $script:cred *>&1 | Out-Null
        Test-Path (Join-Path $script:tkHome 'creds\custom-creds.xml') | Should -Be $true
    }

    It "Should honor -FileName" {
        New-SSHCredential -Credential $script:cred -FileName 'prod.xml' *>&1 | Out-Null
        Test-Path (Join-Path $script:tkHome 'creds\prod.xml') | Should -Be $true
    }

    It "Should refuse to overwrite an existing file without -Force" {
        New-SSHCredential -Credential $script:cred *>&1 | Out-Null
        $other = New-TestCredential -User 'other' -Password 'x'
        $output = New-SSHCredential -Credential $other *>&1 | Out-String
        $output | Should -Match 'already exists'
        (Import-Clixml $script:defaultFile).UserName | Should -Be 'deploy'
    }

    It "Should overwrite with -Force" {
        New-SSHCredential -Credential $script:cred *>&1 | Out-Null
        $other = New-TestCredential -User 'other' -Password 'x'
        New-SSHCredential -Credential $other -Force *>&1 | Out-Null
        (Import-Clixml $script:defaultFile).UserName | Should -Be 'other'
    }

    It "Should report the saved path and user" {
        $output = New-SSHCredential -Credential $script:cred *>&1 | Out-String
        $output | Should -Match 'deploy'
        $output | Should -Match ([regex]::Escape($script:defaultFile))
    }

    It "Should not prompt when -Credential is supplied" {
        Mock -ModuleName PowerShellDevToolkit Get-Credential { throw "Get-Credential must not be called" }
        { New-SSHCredential -Credential $script:cred *>&1 | Out-Null } | Should -Not -Throw
    }

    It "Should prompt with Get-Credential when no credential is supplied" {
        Mock -ModuleName PowerShellDevToolkit Get-Credential {
            New-Object System.Management.Automation.PSCredential('prompted', (ConvertTo-SecureString 'pw' -AsPlainText -Force))
        }
        New-SSHCredential *>&1 | Out-Null
        Should -Invoke -ModuleName PowerShellDevToolkit Get-Credential -Times 1 -Exactly
        (Import-Clixml $script:defaultFile).UserName | Should -Be 'prompted'
    }

    It "Should write nothing when the prompt is cancelled" {
        Mock -ModuleName PowerShellDevToolkit Get-Credential { $null }
        $output = New-SSHCredential *>&1 | Out-String
        Test-Path $script:defaultFile | Should -Be $false
        $output | Should -Match 'Cancelled'
    }
}
