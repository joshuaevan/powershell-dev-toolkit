function Set-FileTimestamp {
    <#
    .SYNOPSIS
        Create a new file or update an existing file's last-write timestamp.

    .DESCRIPTION
        Mimics the Unix touch command: creates the file (and any missing parent
        directories) if it does not exist, or updates its LastWriteTime to now
        if it already exists.

    .PARAMETER Path
        Path of the file to create or touch.

    .EXAMPLE
        touch .\newfile.txt
        Set-FileTimestamp .\newfile.txt
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string]$Path
    )

    process {
        if (Test-Path $Path) {
            (Get-Item $Path).LastWriteTime = [datetime]::Now
        } else {
            $parent = Split-Path $Path -Parent
            if ($parent -and -not (Test-Path $parent)) {
                New-Item -Path $parent -ItemType Directory -Force | Out-Null
            }
            New-Item -Path $Path -ItemType File -Force | Out-Null
        }
    }
}
