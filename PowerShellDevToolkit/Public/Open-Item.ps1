function Open-Item {
    <#
    .SYNOPSIS
        Open a file or folder with its default Windows application.

    .DESCRIPTION
        Passes the given path to Windows Shell (equivalent to double-clicking
        in Explorer). Opens the current directory when no path is given.

    .PARAMETER Path
        File or folder to open. Defaults to the current directory.

    .EXAMPLE
        open .\document.pdf
        open .\project
        open
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Path = '.'
    )

    $resolved = Resolve-Path $Path -ErrorAction SilentlyContinue
    if (-not $resolved) {
        Write-Error "Path not found: $Path"
        return
    }

    Invoke-Item $resolved
}
