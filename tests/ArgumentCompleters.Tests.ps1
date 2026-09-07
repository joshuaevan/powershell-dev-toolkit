BeforeAll {
    $repoRoot  = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    $moduleDir = Join-Path $repoRoot "PowerShellDevToolkit"
    Import-Module $moduleDir -Force -DisableNameChecking
    $script:savedPsdtHome = $env:PSDT_HOME

    $script:tkHome = Join-Path $env:TEMP "pester-completers-$(Get-Random)"
    New-Item -Path $script:tkHome -ItemType Directory -Force | Out-Null
    $env:PSDT_HOME = $script:tkHome
    Set-Content (Join-Path $script:tkHome 'config.json') @'
{
  "ssh": {
    "servers": {
      "alpha": { "hostname": "a.example.com", "description": "Alpha box" },
      "beta":  { "hostname": "b.example.com" }
    },
    "databasePorts": { "postgres": 5432, "mysql": 3306 }
  }
}
'@

    function Get-Completions {
        param([string]$Line)
        (TabExpansion2 -inputScript $Line -cursorColumn $Line.Length).CompletionMatches
    }
}

AfterAll {
    $env:PSDT_HOME = $script:savedPsdtHome
    Remove-Item $script:tkHome -Recurse -Force -ErrorAction SilentlyContinue
}

Describe "SSH argument completers" {
    It "Completes server aliases for Connect-SSH -Target" {
        (Get-Completions 'Connect-SSH al').CompletionText | Should -Contain 'alpha'
    }

    It "Lists every server alias when nothing has been typed" {
        $names = (Get-Completions 'Connect-SSH ').CompletionText
        $names | Should -Contain 'alpha'
        $names | Should -Contain 'beta'
    }

    It "Puts the hostname and description in the tooltip" {
        $match = Get-Completions 'Connect-SSH alpha' | Where-Object CompletionText -eq 'alpha'
        $match.ToolTip | Should -Match 'a\.example\.com'
        $match.ToolTip | Should -Match 'Alpha box'
    }

    It "Completes server aliases through the cssh alias" {
        (Get-Completions 'cssh al').CompletionText | Should -Contain 'alpha'
    }

    It "Completes server aliases for Connect-SSHTunnel" {
        (Get-Completions 'Connect-SSHTunnel be').CompletionText | Should -Contain 'beta'
    }

    It "Completes server aliases through the tunnel alias" {
        (Get-Completions 'tunnel be').CompletionText | Should -Contain 'beta'
    }

    It "Completes database names for the tunnel port argument" {
        $matches = Get-Completions 'Connect-SSHTunnel alpha po'
        $matches.CompletionText | Should -Contain 'postgres'
        ($matches | Where-Object CompletionText -eq 'postgres').ToolTip | Should -Match '5432'
    }

    It "Completes database names through the tunnel alias" {
        (Get-Completions 'tunnel alpha my').CompletionText | Should -Contain 'mysql'
    }

    It "Completes nothing (and prints nothing) when config is missing" {
        $emptyHome = Join-Path $env:TEMP "pester-completers-empty-$(Get-Random)"
        New-Item -Path $emptyHome -ItemType Directory -Force | Out-Null
        $env:PSDT_HOME = $emptyHome
        try {
            $names = (Get-Completions 'Connect-SSH ').CompletionText
            $names | Should -Not -Contain 'alpha'
        } finally {
            $env:PSDT_HOME = $script:tkHome
            Remove-Item $emptyHome -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
