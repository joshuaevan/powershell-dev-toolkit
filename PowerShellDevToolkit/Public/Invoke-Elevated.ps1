function Invoke-Elevated {
    <#
    .SYNOPSIS
        Run a command with administrator privileges.

    .DESCRIPTION
        Launches a new elevated PowerShell window that executes the given
        command and its arguments. The elevated window stays open after the
        command finishes so you can read the output.

    .PARAMETER Command
        The executable or PowerShell expression to run as administrator.

    .PARAMETER ArgumentList
        Arguments to pass to the command.

    .EXAMPLE
        sudo notepad C:\Windows\System32\drivers\etc\hosts
        sudo choco install nodejs
        sudo npm install -g pnpm
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Command,

        [Parameter(Position = 1, ValueFromRemainingArguments)]
        [string[]]$ArgumentList
    )

    $expression = if ($ArgumentList) {
        "$Command $($ArgumentList -join ' ')"
    } else {
        $Command
    }

    Start-Process pwsh -Verb RunAs -ArgumentList "-NoExit", "-Command", $expression
}
