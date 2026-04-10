function Edit-Profile {
    <#
    .SYNOPSIS
        Open the current user's PowerShell profile in the configured editor.

    .DESCRIPTION
        Opens $PROFILE in Notepad++ (or the configured editor). Creates the
        profile file first if it does not yet exist.

    .EXAMPLE
        Edit-Profile
    #>
    [CmdletBinding()]
    param()

    if (-not (Test-Path $PROFILE)) {
        New-Item -Path $PROFILE -ItemType File -Force | Out-Null
        Write-Host "Created profile: $PROFILE" -ForegroundColor Green
    }

    Edit-File $PROFILE
}
