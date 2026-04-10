$scriptDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Describe "Invoke-QuickRequest" {
    It "Should GET a URL and return JSON with status" {
        $raw = & "$scriptDir\Invoke-QuickRequest.ps1" GET "https://httpbin.org/get" -AsJson 2>$null
        $result = $raw | ConvertFrom-Json
        $result.status | Should Be 200
        ($null -ne $result.elapsed) | Should Be $true
        ($null -ne $result.contentType) | Should Be $true
    }

    It "Should return raw body with -Raw" {
        $raw = & "$scriptDir\Invoke-QuickRequest.ps1" GET "https://httpbin.org/get" -Raw 2>$null
        ($raw -match 'headers') | Should Be $true
    }

    It "Should return error JSON for unreachable host" {
        $raw = & "$scriptDir\Invoke-QuickRequest.ps1" GET "http://192.0.2.1:1" -AsJson 2>$null
        $result = $raw | ConvertFrom-Json
        $result.error | Should Not BeNullOrEmpty
    }

    It "Should include body in JSON response" {
        $raw = & "$scriptDir\Invoke-QuickRequest.ps1" GET "https://httpbin.org/json" -AsJson 2>$null
        $result = $raw | ConvertFrom-Json
        $result.body | Should Not BeNullOrEmpty
    }
}
