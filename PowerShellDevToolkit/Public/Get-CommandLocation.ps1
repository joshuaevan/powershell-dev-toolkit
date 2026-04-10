function Get-CommandLocation {
    <#
    .SYNOPSIS
        Find the location of a command or executable.

    .DESCRIPTION
        Returns the full path to the specified command, similar to Unix's which.
        Reports all matches when -All is specified.

    .PARAMETER Name
        Name of the command to locate.

    .PARAMETER All
        Return all matching commands instead of just the first.

    .EXAMPLE
        which node
        which git
        which python -All
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name,

        [switch]$All
    )

    $commands = Get-Command $Name -ErrorAction SilentlyContinue -All:$All

    if (-not $commands) {
        Write-Warning "${Name}: command not found"
        return
    }

    foreach ($cmd in @($commands)) {
        if ($cmd.Source) {
            $cmd.Source
        } elseif ($cmd.Definition) {
            $cmd.Definition
        } else {
            "$($cmd.CommandType): $($cmd.Name)"
        }
    }
}
