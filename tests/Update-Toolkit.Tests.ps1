BeforeAll {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $repoRoot "PowerShellDevToolkit") -Force -DisableNameChecking
}

Describe "Update-Toolkit" {
    It "Should be exported from the module" {
        $cmd = Get-Command Update-Toolkit -Module PowerShellDevToolkit -ErrorAction SilentlyContinue
        ($null -ne $cmd) | Should -Be $true
    }

    It "Should expose -CheckOnly and -Force parameters" {
        $info = Get-Command Update-Toolkit -Module PowerShellDevToolkit
        ($info.Parameters.ContainsKey('CheckOnly')) | Should -Be $true
        ($info.Parameters.ContainsKey('Force'))     | Should -Be $true
    }

    It "Should report status when run with -CheckOnly" {
        $output = Update-Toolkit -CheckOnly *>&1 | Out-String
        $hasStatus = ($output -match 'up to date') -or ($output -match 'available') -or ($output -match 'not a git')
        $hasStatus | Should -Be $true
    }

    It "Should show current version when up to date" {
        $output = Update-Toolkit -CheckOnly *>&1 | Out-String
        if ($output -match 'up to date') {
            ($output -match 'Version') | Should -Be $true
        }
    }
}

Describe "Test-ToolkitUpdate" {
    It "Should be exported from the module" {
        $cmd = Get-Command Test-ToolkitUpdate -Module PowerShellDevToolkit -ErrorAction SilentlyContinue
        ($null -ne $cmd) | Should -Be $true
    }

    It "Should not throw on a valid git repo" {
        { Test-ToolkitUpdate } | Should -Not -Throw
    }
}

Describe "Set-ToolkitUpdateTimestamp" {
    It "Should create the stamp file" {
        $stampFile = Join-Path $repoRoot ".last-update-check"
        if (Test-Path $stampFile) { Remove-Item $stampFile }
        & (Get-Module PowerShellDevToolkit) { Set-ToolkitUpdateTimestamp }
        (Test-Path $stampFile) | Should -Be $true
        Remove-Item $stampFile -ErrorAction SilentlyContinue
    }

    It "Should write a valid ISO 8601 timestamp" {
        & (Get-Module PowerShellDevToolkit) { Set-ToolkitUpdateTimestamp }
        $stampFile = Join-Path $repoRoot ".last-update-check"
        $content = Get-Content $stampFile -Raw
        { [datetime]::Parse($content) } | Should -Not -Throw
        Remove-Item $stampFile -ErrorAction SilentlyContinue
    }
}

Describe "Update-Toolkit on a Gallery install" {
    BeforeAll {
        $repoRoot  = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
        $moduleDir = Join-Path $repoRoot "PowerShellDevToolkit"
        $global:PesterGalleryHome = Join-Path $env:TEMP "pester-gallery-update-$(Get-Random)"
        New-Item -Path $global:PesterGalleryHome -ItemType Directory -Force | Out-Null
        $global:PesterGalleryModuleDir = $moduleDir
        $global:PesterInstalledVersion = (Import-PowerShellDataFile (Join-Path $moduleDir "PowerShellDevToolkit.psd1")).ModuleVersion
    }

    AfterAll {
        Remove-Item $global:PesterGalleryHome -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Variable -Name PesterGalleryHome, PesterGalleryModuleDir, PesterInstalledVersion -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeEach {
        Mock -ModuleName PowerShellDevToolkit Get-ToolkitPaths {
            [pscustomobject]@{
                InstallType       = 'Gallery'
                ModuleRoot        = $global:PesterGalleryModuleDir
                RepoRoot          = $null
                DataRoot          = $global:PesterGalleryHome
                ConfigPath        = Join-Path $global:PesterGalleryHome 'config.json'
                ExampleConfigPath = Join-Path $global:PesterGalleryModuleDir 'config.example.json'
                CredsPath         = Join-Path $global:PesterGalleryHome 'creds'
                UpdateStampPath   = Join-Path $global:PesterGalleryHome '.last-update-check'
            }
        }
        Mock -ModuleName PowerShellDevToolkit Read-Host { throw "Read-Host must not be called with -CheckOnly" }
        Mock -ModuleName PowerShellDevToolkit Update-Module { throw "Update-Module must not be called with -CheckOnly" }
        Remove-Item (Join-Path $global:PesterGalleryHome '.last-update-check') -ErrorAction SilentlyContinue
    }

    It "Reports up to date when the Gallery version matches" {
        Mock -ModuleName PowerShellDevToolkit Find-Module { [pscustomobject]@{ Version = $global:PesterInstalledVersion; ReleaseNotes = $null } }
        $output = Update-Toolkit -CheckOnly *>&1 | Out-String
        $output | Should -Match 'up to date'
        $output | Should -Match 'Gallery'
        $output | Should -Match ([regex]::Escape($global:PesterInstalledVersion))
    }

    It "Reports an available update with release notes" {
        Mock -ModuleName PowerShellDevToolkit Find-Module { [pscustomobject]@{ Version = '99.0.0'; ReleaseNotes = 'Big new things' } }
        $output = Update-Toolkit -CheckOnly *>&1 | Out-String
        $output | Should -Match 'Update available'
        $output | Should -Match '99\.0\.0'
        $output | Should -Match 'Big new things'
    }

    It "Reports when the Gallery cannot be reached" {
        Mock -ModuleName PowerShellDevToolkit Find-Module { throw "no network" }
        $output = Update-Toolkit -CheckOnly *>&1 | Out-String
        $output | Should -Match 'Could not reach the PowerShell Gallery'
    }

    It "Does not mention git on a Gallery install" {
        Mock -ModuleName PowerShellDevToolkit Find-Module { [pscustomobject]@{ Version = $global:PesterInstalledVersion; ReleaseNotes = $null } }
        $output = Update-Toolkit -CheckOnly *>&1 | Out-String
        $output | Should -Not -Match 'not a git repository'
    }

    It "Never prompts or installs with -CheckOnly" {
        Mock -ModuleName PowerShellDevToolkit Find-Module { [pscustomobject]@{ Version = '99.0.0'; ReleaseNotes = $null } }
        { Update-Toolkit -CheckOnly *>&1 | Out-Null } | Should -Not -Throw
    }
}

Describe "Test-ToolkitUpdate on a Gallery install" {
    BeforeAll {
        $repoRoot  = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
        $moduleDir = Join-Path $repoRoot "PowerShellDevToolkit"
        $global:PesterGalleryHome = Join-Path $env:TEMP "pester-gallery-check-$(Get-Random)"
        New-Item -Path $global:PesterGalleryHome -ItemType Directory -Force | Out-Null
        $global:PesterGalleryModuleDir = $moduleDir
        $global:PesterStampPath = Join-Path $global:PesterGalleryHome '.last-update-check'
    }

    AfterAll {
        Remove-Item $global:PesterGalleryHome -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Variable -Name PesterGalleryHome, PesterGalleryModuleDir, PesterStampPath -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeEach {
        Mock -ModuleName PowerShellDevToolkit Get-ToolkitPaths {
            [pscustomobject]@{
                InstallType       = 'Gallery'
                ModuleRoot        = $global:PesterGalleryModuleDir
                RepoRoot          = $null
                DataRoot          = $global:PesterGalleryHome
                ConfigPath        = Join-Path $global:PesterGalleryHome 'config.json'
                ExampleConfigPath = Join-Path $global:PesterGalleryModuleDir 'config.example.json'
                CredsPath         = Join-Path $global:PesterGalleryHome 'creds'
                UpdateStampPath   = $global:PesterStampPath
            }
        }
        Remove-Item $global:PesterStampPath -ErrorAction SilentlyContinue
    }

    It "Prints the update hint when a newer version exists" {
        Mock -ModuleName PowerShellDevToolkit Find-Module { [pscustomobject]@{ Version = '99.0.0'; ReleaseNotes = $null } }
        $output = Test-ToolkitUpdate *>&1 | Out-String
        $output | Should -Match 'Update-Toolkit'
        $output | Should -Match '99\.0\.0'
    }

    It "Prints nothing when up to date" {
        $installed = (Import-PowerShellDataFile (Join-Path $global:PesterGalleryModuleDir "PowerShellDevToolkit.psd1")).ModuleVersion
        $global:PesterInstalledVersion = $installed
        Mock -ModuleName PowerShellDevToolkit Find-Module { [pscustomobject]@{ Version = $global:PesterInstalledVersion; ReleaseNotes = $null } }
        $output = Test-ToolkitUpdate *>&1 | Out-String
        $output.Trim() | Should -BeNullOrEmpty
    }

    It "Writes the stamp file after checking" {
        Mock -ModuleName PowerShellDevToolkit Find-Module { [pscustomobject]@{ Version = '0.0.1'; ReleaseNotes = $null } }
        Test-ToolkitUpdate *>&1 | Out-Null
        Test-Path $global:PesterStampPath | Should -Be $true
    }

    It "Creates the data folder for the stamp when it does not exist" {
        Remove-Item $global:PesterGalleryHome -Recurse -Force -ErrorAction SilentlyContinue
        Mock -ModuleName PowerShellDevToolkit Find-Module { [pscustomobject]@{ Version = '0.0.1'; ReleaseNotes = $null } }
        Test-ToolkitUpdate *>&1 | Out-Null
        Test-Path $global:PesterStampPath | Should -Be $true
    }

    It "Skips the Gallery call when the stamp is fresh" {
        New-Item -Path $global:PesterGalleryHome -ItemType Directory -Force | Out-Null
        [IO.File]::WriteAllText($global:PesterStampPath, (Get-Date -Format 'o'))
        Mock -ModuleName PowerShellDevToolkit Find-Module { [pscustomobject]@{ Version = '99.0.0'; ReleaseNotes = $null } }
        Test-ToolkitUpdate *>&1 | Out-Null
        Should -Invoke -ModuleName PowerShellDevToolkit Find-Module -Times 0 -Exactly
    }

    It "Never throws when the Gallery is unreachable" {
        Mock -ModuleName PowerShellDevToolkit Find-Module { throw "no network" }
        { Test-ToolkitUpdate *>&1 | Out-Null } | Should -Not -Throw
    }
}
