BeforeAll {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $repoRoot "PowerShellDevToolkit") -Force
}

Describe "Use-NppForGit" {
    It "Should be exported from the module" {
        $cmd = Get-Command Use-NppForGit -ErrorAction SilentlyContinue
        ($null -ne $cmd) | Should -Be $true
    }

    It "Should report an error when Notepad++ is not installed anywhere" {
        $nppPaths = @(
            "${env:ProgramFiles}\Notepad++\notepad++.exe",
            "${env:ProgramFiles(x86)}\Notepad++\notepad++.exe",
            "${env:LOCALAPPDATA}\Programs\Notepad++\notepad++.exe"
        )
        $nppInstalled = ($nppPaths | Where-Object { Test-Path $_ } | Measure-Object).Count -gt 0
        if (-not $nppInstalled) {
            $nppInstalled = [bool](Get-Command 'notepad++' -ErrorAction SilentlyContinue)
        }

        if ($nppInstalled) {
            Write-Host "  Skipping: Notepad++ is installed, cannot test 'not found' path." -ForegroundColor Yellow
            return
        }

        $configPath = Join-Path $repoRoot "config.json"
        $savedConfig = $null
        if (Test-Path $configPath) { $savedConfig = Get-Content $configPath -Raw }

        try {
            '{"editor":{"notepadPlusPlus":"C:\\does_not_exist\\notepad++.exe"}}' | Set-Content $configPath
            $output = Use-NppForGit *>&1 | Out-String
            ($output -match 'not found|cannot find|does not exist|failed') | Should -Be $true
        } finally {
            if ($savedConfig) {
                Set-Content $configPath $savedConfig
            } else {
                Remove-Item $configPath -ErrorAction SilentlyContinue
            }
        }
    }

    It "Should set git core.editor when Notepad++ exists" {
        $nppPaths = @(
            "${env:ProgramFiles}\Notepad++\notepad++.exe",
            "${env:ProgramFiles(x86)}\Notepad++\notepad++.exe",
            "${env:LOCALAPPDATA}\Programs\Notepad++\notepad++.exe"
        )
        $nppFound = $nppPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

        if (-not $nppFound) {
            Write-Host "  Skipping: Notepad++ not installed on this machine." -ForegroundColor Yellow
            return
        }

        $previousEditor = git config --global core.editor 2>$null
        try {
            Use-NppForGit 2>$null
            $newEditor = git config --global core.editor 2>$null
            ($newEditor -match 'notepad\+\+') | Should -Be $true
        } finally {
            if ($previousEditor) {
                git config --global core.editor $previousEditor
            } else {
                git config --global --unset core.editor 2>$null
            }
        }
    }
}
