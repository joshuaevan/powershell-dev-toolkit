function Add-Path {
    <#
    .SYNOPSIS
        Add a directory to the system or user PATH environment variable.

    .DESCRIPTION
        Appends the given directory to the PATH for the current session and
        persists the change to either the User or Machine environment store.
        Skips silently if the directory is already present.

    .PARAMETER Path
        Directory to add to PATH.

    .PARAMETER User
        Persist to the current user's PATH instead of the machine PATH.
        Machine PATH requires administrator privileges.

    .EXAMPLE
        Add-Path "C:\tools\bin"
        Add-Path "C:\tools\bin" -User
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path,

        [switch]$User
    )

    $scope = if ($User) { 'User' } else { 'Machine' }

    $current = [System.Environment]::GetEnvironmentVariable('Path', $scope)
    $entries = $current -split ';' | Where-Object { $_ -ne '' }

    if ($entries -contains $Path) {
        Write-Host "Already in $scope PATH: $Path" -ForegroundColor Yellow
        return
    }

    $newValue = ($entries + $Path) -join ';'

    try {
        [System.Environment]::SetEnvironmentVariable('Path', $newValue, $scope)
        $env:Path = "$env:Path;$Path"
        Write-Host "Added to $scope PATH: $Path" -ForegroundColor Green
    } catch {
        Write-Error "Failed to update $scope PATH. $_"
        Write-Host "Tip: Run as administrator for Machine-scope changes, or use -User." -ForegroundColor Yellow
    }
}
