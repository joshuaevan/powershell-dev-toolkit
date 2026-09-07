BeforeAll {
    $repoRoot  = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    $moduleDir = Join-Path $repoRoot "PowerShellDevToolkit"
    Import-Module $moduleDir -Force -DisableNameChecking
    $script:savedPsdtHome = $env:PSDT_HOME

    $script:tkHome = Join-Path $env:TEMP "pester-resolve-$(Get-Random)"
    $script:credsDir = Join-Path $script:tkHome 'creds'
    New-Item -Path $script:credsDir -ItemType Directory -Force | Out-Null
    $env:PSDT_HOME = $script:tkHome

    $script:keyPath = Join-Path $script:credsDir 'aws.pem'
    Set-Content $script:keyPath "-----BEGIN FAKE KEY-----"

    $cred = New-Object System.Management.Automation.PSCredential('creduser', (ConvertTo-SecureString 'secret' -AsPlainText -Force))
    $cred | Export-Clixml (Join-Path $script:credsDir 'ssh-credentials.xml')

    $script:config = @"
{
  "ssh": {
    "credentialFile": "ssh-credentials.xml",
    "servers": {
      "keyed":      { "hostname": "keyed.example.com",   "keyFile": "aws.pem", "user": "ec2-user" },
      "keyonly":    { "hostname": "keyonly.example.com", "keyFile": "aws.pem" },
      "pw":         { "hostname": "pw.example.com" },
      "missingkey": { "hostname": "mk.example.com",      "keyFile": "nope.pem" },
      "absolute":   { "hostname": "abs.example.com",     "keyFile": "$($script:keyPath -replace '\\', '\\')", "user": "root" }
    }
  }
}
"@ | ConvertFrom-Json

    function Resolve-Target {
        param([string]$Target, $Config)
        & (Get-Module PowerShellDevToolkit) { param($t, $c) Resolve-SSHTarget -Target $t -Config $c } $Target $Config
    }
}

AfterAll {
    $env:PSDT_HOME = $script:savedPsdtHome
    Remove-Item $script:tkHome -Recurse -Force -ErrorAction SilentlyContinue
}

Describe "Resolve-SSHTarget" {
    It "Resolves an alias with a key file and explicit user" {
        $r = Resolve-Target -Target 'keyed' -Config $script:config
        $r.Server      | Should -Be 'keyed.example.com'
        $r.UserName    | Should -Be 'ec2-user'
        $r.KeyFilePath | Should -Be $script:keyPath
        $r.Password    | Should -BeNullOrEmpty
    }

    It "Falls back to the credential file username for key auth without a user" {
        $r = Resolve-Target -Target 'keyonly' -Config $script:config
        $r.UserName    | Should -Be 'creduser'
        $r.KeyFilePath | Should -Be $script:keyPath
    }

    It "Loads username and password from the credential file for password auth" {
        $r = Resolve-Target -Target 'pw' -Config $script:config
        $r.Server      | Should -Be 'pw.example.com'
        $r.UserName    | Should -Be 'creduser'
        $r.Password    | Should -Be 'secret'
        $r.Credential  | Should -Not -BeNullOrEmpty
        $r.KeyFilePath | Should -BeNullOrEmpty
    }

    It "Treats an unknown target as a raw hostname" {
        $r = Resolve-Target -Target 'raw.example.com' -Config $script:config
        $r.Server   | Should -Be 'raw.example.com'
        $r.UserName | Should -Be 'creduser'
    }

    It "Accepts an absolute key file path" {
        $r = Resolve-Target -Target 'absolute' -Config $script:config
        $r.KeyFilePath | Should -Be $script:keyPath
        $r.UserName    | Should -Be 'root'
    }

    It "Returns null and reports a missing key file" {
        $output = Resolve-Target -Target 'missingkey' -Config $script:config *>&1 | Out-String
        $r = Resolve-Target -Target 'missingkey' -Config $script:config 6>$null
        $r | Should -BeNullOrEmpty
        $output | Should -Match 'Key file not found'
        $output | Should -Match 'nope\.pem'
    }

    It "Returns null and reports a missing credential file" {
        $cfg = '{ "ssh": { "credentialFile": "nope.xml", "servers": { "pw": { "hostname": "pw.example.com" } } } }' | ConvertFrom-Json
        $output = Resolve-Target -Target 'pw' -Config $cfg *>&1 | Out-String
        $r = Resolve-Target -Target 'pw' -Config $cfg 6>$null
        $r | Should -BeNullOrEmpty
        $output | Should -Match 'Credential file not found'
    }

    It "Returns null when key auth has no username anywhere" {
        $cfg = '{ "ssh": { "servers": { "keyonly": { "hostname": "k.example.com", "keyFile": "aws.pem" } } } }' | ConvertFrom-Json
        $output = Resolve-Target -Target 'keyonly' -Config $cfg *>&1 | Out-String
        $r = Resolve-Target -Target 'keyonly' -Config $cfg 6>$null
        $r | Should -BeNullOrEmpty
        $output | Should -Match 'Username required'
    }

    It "Defaults the credential file name to ssh-credentials.xml" {
        $cfg = '{ "ssh": { "servers": { "pw": { "hostname": "pw.example.com" } } } }' | ConvertFrom-Json
        $r = Resolve-Target -Target 'pw' -Config $cfg
        $r.UserName | Should -Be 'creduser'
    }
}

Describe "Test-WslAvailable" {
    It "Returns a boolean" {
        $r = & (Get-Module PowerShellDevToolkit) { Test-WslAvailable }
        $r | Should -BeOfType [bool]
    }

    It "Returns false when wsl is not on the path" {
        Mock -ModuleName PowerShellDevToolkit Get-Command { $null } -ParameterFilter { $Name -eq 'wsl' }
        $r = & (Get-Module PowerShellDevToolkit) { Test-WslAvailable }
        $r | Should -Be $false
    }
}
