function Set-TempLocation {
    <#
    .SYNOPSIS
        Navigate to the Windows temporary directory.

    .DESCRIPTION
        Changes the current location to $env:TEMP.

    .EXAMPLE
        temp
        Set-TempLocation
    #>
    [CmdletBinding()]
    param()

    Set-Location $env:TEMP
}
