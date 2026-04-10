$scriptDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Describe "helpme" {
    It "Should run without error" {
        $output = & "$scriptDir\helpme.ps1" *>&1 | Out-String
        $output | Should Not BeNullOrEmpty
    }

    It "Should contain SSH command references" {
        $output = & "$scriptDir\helpme.ps1" *>&1 | Out-String
        ($output -match 'cssh') | Should Be $true
        ($output -match 'tunnel') | Should Be $true
    }

    It "Should contain development command references" {
        $output = & "$scriptDir\helpme.ps1" *>&1 | Out-String
        ($output -match 'gs') | Should Be $true
        ($output -match 'serve') | Should Be $true
        ($output -match 'port') | Should Be $true
        ($output -match 'search') | Should Be $true
    }

    It "Should contain utility command references" {
        $output = & "$scriptDir\helpme.ps1" *>&1 | Out-String
        ($output -match 'reload') | Should Be $true
        ($output -match 'recent-commands') | Should Be $true
    }

    It "Should contain AI integration section" {
        $output = & "$scriptDir\helpme.ps1" *>&1 | Out-String
        ($output -match 'ai-rules') | Should Be $true
        ($output -match 'context') | Should Be $true
    }
}
