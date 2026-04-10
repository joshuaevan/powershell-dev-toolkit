$scriptDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Describe "Get-PortProcess" {
    It "Should report free port as status free" {
        $raw = & "$scriptDir\Get-PortProcess.ps1" -Port 59999 -AsJson 2>$null
        $result = $raw | ConvertFrom-Json
        $result.status | Should Be 'free'
        $result.port | Should Be 59999
    }

    It "Should return list of listening ports with -List -AsJson" {
        $raw = & "$scriptDir\Get-PortProcess.ps1" -List -AsJson 2>$null
        $result = $raw | ConvertFrom-Json
        ($result | Measure-Object).Count | Should BeGreaterThan 0
        $first = $result[0]
        ($null -ne $first.port) | Should Be $true
        ($null -ne $first.pid) | Should Be $true
        ($null -ne $first.process) | Should Be $true
    }

    It "Should show usage when no port specified" {
        $output = & "$scriptDir\Get-PortProcess.ps1" *>&1 | Out-String
        ($output -match 'Usage') | Should Be $true
    }
}
