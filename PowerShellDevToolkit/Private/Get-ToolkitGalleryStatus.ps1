function Get-ToolkitGalleryStatus {
    <#
    .SYNOPSIS
        Compare the installed module version with the PowerShell Gallery.

    .PARAMETER Paths
        The object returned by Get-ToolkitPaths.

    .OUTPUTS
        PSCustomObject with Installed, Latest, UpdateAvailable and ReleaseNotes,
        or $null when the Gallery cannot be reached.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Paths
    )

    $manifest  = Import-PowerShellDataFile (Join-Path $Paths.ModuleRoot 'PowerShellDevToolkit.psd1')
    $installed = [version]$manifest.ModuleVersion

    try {
        $latest = Find-Module -Name PowerShellDevToolkit -Repository PSGallery -ErrorAction Stop
    }
    catch {
        return $null
    }
    if (-not $latest) { return $null }

    $latestVersion = [version]$latest.Version

    return [pscustomobject]@{
        Installed       = $installed
        Latest          = $latestVersion
        UpdateAvailable = ($latestVersion -gt $installed)
        ReleaseNotes    = $latest.ReleaseNotes
    }
}
