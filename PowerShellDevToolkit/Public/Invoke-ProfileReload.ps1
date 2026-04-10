function Invoke-ProfileReload {
    <#
    .SYNOPSIS
        Reload the current user's PowerShell profile without restarting the terminal.

    .DESCRIPTION
        Dot-sources $PROFILE in the current session, applying any changes made
        since the terminal was opened.

    .EXAMPLE
        reload
        Invoke-ProfileReload
    #>
    [CmdletBinding()]
    param()

    if (Test-Path $PROFILE) {
        . $PROFILE
        Write-Host "Profile reloaded: $PROFILE" -ForegroundColor Green
    } else {
        Write-Warning "No profile file found at: $PROFILE"
    }
}
