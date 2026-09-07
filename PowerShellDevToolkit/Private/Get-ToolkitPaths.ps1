function Get-ToolkitPaths {
    <#
    .SYNOPSIS
        Resolve every on-disk location the toolkit uses.

    .DESCRIPTION
        Returns an object describing where the module lives, whether it was
        installed from a git checkout or the PowerShell Gallery, and where user
        data (config.json, the creds folder, the update-check stamp) is stored.

        Data folder resolution order:
          1. $env:PSDT_HOME when set
          2. The repo root when the module sits inside a git checkout
          3. $env:LOCALAPPDATA\PowerShellDevToolkit

        Evaluated on every call so PSDT_HOME can change at runtime.

    .EXAMPLE
        $paths = Get-ToolkitPaths
        $paths.ConfigPath
    #>
    [CmdletBinding()]
    param()

    $moduleRoot = $script:ModuleRoot
    $parentDir  = Split-Path $moduleRoot -Parent
    $isGit      = Test-Path (Join-Path $parentDir '.git')

    $dataRoot = if (-not [string]::IsNullOrWhiteSpace($env:PSDT_HOME)) {
        $env:PSDT_HOME
    } elseif ($isGit) {
        $parentDir
    } else {
        Join-Path $env:LOCALAPPDATA 'PowerShellDevToolkit'
    }

    [pscustomobject]@{
        InstallType       = if ($isGit) { 'Git' } else { 'Gallery' }
        ModuleRoot        = $moduleRoot
        RepoRoot          = if ($isGit) { $parentDir } else { $null }
        DataRoot          = $dataRoot
        ConfigPath        = Join-Path $dataRoot 'config.json'
        ExampleConfigPath = Join-Path $moduleRoot 'config.example.json'
        CredsPath         = Join-Path $dataRoot 'creds'
        UpdateStampPath   = Join-Path $dataRoot '.last-update-check'
    }
}
