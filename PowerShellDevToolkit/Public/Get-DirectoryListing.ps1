function Get-DirectoryListing {
    <#
    .SYNOPSIS
        Enhanced directory listing with directories sorted first.

    .DESCRIPTION
        Lists directory contents in a formatted table with folders displayed
        before files. Use -Force to include hidden and system items (equivalent
        to Unix's ls -la).

    .PARAMETER Path
        Directory to list. Defaults to the current directory.

    .PARAMETER Force
        Include hidden and system files in the listing.

    .EXAMPLE
        ll
        ll .\src
        la
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Path = '.',

        [switch]$Force
    )

    $params = @{ Path = $Path }
    if ($Force) { $params['Force'] = $true }

    Get-ChildItem @params |
        Sort-Object { -not $_.PSIsContainer }, Name |
        Format-Table -AutoSize -Property @(
            @{ Label = 'Mode';          Expression = { $_.Mode } },
            @{ Label = 'LastWriteTime'; Expression = { $_.LastWriteTime.ToString('yyyy-MM-dd HH:mm') } },
            @{ Label = 'Length';        Expression = { if ($_.PSIsContainer) { '<DIR>' } else { $_.Length.ToString('N0') } }; Align = 'Right' },
            @{ Label = 'Name';          Expression = { if ($_.PSIsContainer) { "$($_.Name)\" } else { $_.Name } } }
        )
}
