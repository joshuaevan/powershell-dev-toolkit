function New-DirectoryAndEnter {
    <#
    .SYNOPSIS
        Create a directory and immediately navigate into it.

    .DESCRIPTION
        Combines New-Item and Set-Location into a single command. Creates any
        missing intermediate directories automatically.

    .PARAMETER Path
        Path of the directory to create and enter.

    .EXAMPLE
        mkcd new-project
        New-DirectoryAndEnter .\projects\my-app
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path
    )

    New-Item -Path $Path -ItemType Directory -Force | Out-Null
    Set-Location $Path
}
