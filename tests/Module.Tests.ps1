BeforeAll {
    $repoRoot  = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    $moduleDir = Join-Path $repoRoot "PowerShellDevToolkit"
    $manifestPath = Join-Path $moduleDir "PowerShellDevToolkit.psd1"
    Import-Module $moduleDir -Force -DisableNameChecking
}

Describe "Module package" {
    It "Ships config.example.json inside the module folder" {
        Test-Path (Join-Path $moduleDir "config.example.json") | Should -Be $true
    }

    It "Does not keep a second copy of config.example.json at the repo root" {
        Test-Path (Join-Path $repoRoot "config.example.json") | Should -Be $false
    }

    It "Passes Test-ModuleManifest" {
        { Test-ModuleManifest $manifestPath -ErrorAction Stop | Out-Null } | Should -Not -Throw
    }

    It "Exports every function listed in the manifest" {
        $manifest = Import-PowerShellDataFile $manifestPath
        foreach ($fn in $manifest.FunctionsToExport) {
            (Get-Command $fn -Module PowerShellDevToolkit -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty -Because "$fn is listed in FunctionsToExport"
        }
    }

    It "Defines every alias listed in the manifest" {
        $manifest = Import-PowerShellDataFile $manifestPath
        foreach ($alias in $manifest.AliasesToExport) {
            (Get-Alias $alias -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty -Because "$alias is listed in AliasesToExport"
        }
    }

    It "Is version 1.2.0" {
        (Import-PowerShellDataFile $manifestPath).ModuleVersion | Should -Be '1.2.0'
    }

    It "Has release notes for 1.2.0" {
        $notes = (Import-PowerShellDataFile $manifestPath).PrivateData.PSData.ReleaseNotes
        $notes | Should -Match '1\.2\.0'
        $notes | Should -Match 'Initialize-Toolkit'
    }

    It "Has a CHANGELOG entry for 1.2.0" {
        (Get-Content (Join-Path $repoRoot "CHANGELOG.md") -Raw) | Should -Match '## \[1\.2\.0\]'
    }
}
