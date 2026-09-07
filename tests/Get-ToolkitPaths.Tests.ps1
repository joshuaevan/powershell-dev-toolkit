BeforeAll {
    $repoRoot  = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    $moduleDir = Join-Path $repoRoot "PowerShellDevToolkit"
    Import-Module $moduleDir -Force -DisableNameChecking
    $script:savedPsdtHome = $env:PSDT_HOME
}

AfterAll {
    $env:PSDT_HOME = $script:savedPsdtHome
}

Describe "Get-ToolkitPaths" {
    BeforeEach {
        $env:PSDT_HOME = $null
    }

    It "Reports a Git install when running from the repo checkout" {
        $p = & (Get-Module PowerShellDevToolkit) { Get-ToolkitPaths }
        $p.InstallType | Should -Be 'Git'
        $p.ModuleRoot  | Should -Be $moduleDir
        $p.RepoRoot    | Should -Be $repoRoot
        $p.DataRoot    | Should -Be $repoRoot
    }

    It "Derives config, creds, stamp and example paths from the roots" {
        $p = & (Get-Module PowerShellDevToolkit) { Get-ToolkitPaths }
        $p.ConfigPath        | Should -Be (Join-Path $repoRoot 'config.json')
        $p.CredsPath         | Should -Be (Join-Path $repoRoot 'creds')
        $p.UpdateStampPath   | Should -Be (Join-Path $repoRoot '.last-update-check')
        $p.ExampleConfigPath | Should -Be (Join-Path $moduleDir 'config.example.json')
    }

    It "Honors PSDT_HOME for the data folder without changing the install type" {
        $env:PSDT_HOME = Join-Path $env:TEMP "pester-psdt-home-$(Get-Random)"
        $p = & (Get-Module PowerShellDevToolkit) { Get-ToolkitPaths }
        $p.InstallType | Should -Be 'Git'
        $p.DataRoot    | Should -Be $env:PSDT_HOME
        $p.ConfigPath  | Should -Be (Join-Path $env:PSDT_HOME 'config.json')
        $p.CredsPath   | Should -Be (Join-Path $env:PSDT_HOME 'creds')
    }

    It "Re-evaluates PSDT_HOME on every call" {
        $env:PSDT_HOME = 'C:\psdt-first'
        (& (Get-Module PowerShellDevToolkit) { Get-ToolkitPaths }).DataRoot | Should -Be 'C:\psdt-first'
        $env:PSDT_HOME = 'C:\psdt-second'
        (& (Get-Module PowerShellDevToolkit) { Get-ToolkitPaths }).DataRoot | Should -Be 'C:\psdt-second'
    }

    It "Ignores a whitespace-only PSDT_HOME" {
        $env:PSDT_HOME = '   '
        (& (Get-Module PowerShellDevToolkit) { Get-ToolkitPaths }).DataRoot | Should -Be $repoRoot
    }

    It "Falls back to LocalAppData for a Gallery-style install" {
        $tempDir = Join-Path $env:TEMP "pester-gallery-$(Get-Random)"
        $version = (Import-PowerShellDataFile (Join-Path $moduleDir 'PowerShellDevToolkit.psd1')).ModuleVersion
        $target  = Join-Path $tempDir "Modules\PowerShellDevToolkit\$version"
        New-Item -Path $target -ItemType Directory -Force | Out-Null
        Copy-Item "$moduleDir\*" $target -Recurse -Force
        try {
            $cmd = "`$env:PSDT_HOME = `$null; `$env:PSDT_SKIP_UPDATE_CHECK = '1'; " +
                   "Import-Module '$target\PowerShellDevToolkit.psd1' -Force -DisableNameChecking; " +
                   "`$p = & (Get-Module PowerShellDevToolkit) { Get-ToolkitPaths }; " +
                   "`$p.InstallType; `$p.DataRoot; [string]`$p.RepoRoot; `$p.ModuleRoot"
            $output = @(pwsh -NoProfile -NonInteractive -Command $cmd)
            $output[0] | Should -Be 'Gallery'
            $output[1] | Should -Be (Join-Path $env:LOCALAPPDATA 'PowerShellDevToolkit')
            $output[2] | Should -BeNullOrEmpty
            # Compare the tail, not the exact path: some runners hand out an 8.3
            # short-form TEMP (RUNNER~1) while $PSScriptRoot resolves to the long form.
            $output[3] | Should -BeLike "*\Modules\PowerShellDevToolkit\$version"
        } finally {
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
