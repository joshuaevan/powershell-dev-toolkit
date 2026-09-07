function Register-ToolkitArgumentCompleters {
    <#
    .SYNOPSIS
        Register tab completion for SSH server aliases and database port names.

    .DESCRIPTION
        Called once when the module loads. Completers read config.json quietly
        on every Tab press, so edits to config.json are picked up without
        re-importing the module.
    #>
    [CmdletBinding()]
    param()

    $serverCompleter = {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

        $config = Get-ScriptConfig -Quiet
        if (-not ($config -and $config.ssh -and $config.ssh.servers)) { return }

        foreach ($prop in $config.ssh.servers.PSObject.Properties) {
            if ($prop.Name -like "$wordToComplete*") {
                $tooltip = [string]$prop.Value.hostname
                if ($prop.Value.description) { $tooltip = "$tooltip - $($prop.Value.description)" }
                [System.Management.Automation.CompletionResult]::new($prop.Name, $prop.Name, 'ParameterValue', $tooltip)
            }
        }
    }

    $dbPortCompleter = {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

        $config = Get-ScriptConfig -Quiet
        if (-not ($config -and $config.ssh -and $config.ssh.databasePorts)) { return }

        foreach ($prop in $config.ssh.databasePorts.PSObject.Properties) {
            if ($prop.Name -like "$wordToComplete*") {
                [System.Management.Automation.CompletionResult]::new($prop.Name, $prop.Name, 'ParameterValue', "port $($prop.Value)")
            }
        }
    }

    $sshCommands    = @('Connect-SSH', 'Connect-SSHTunnel', 'cssh', 'tunnel', 'tssh')
    $tunnelCommands = @('Connect-SSHTunnel', 'tunnel', 'tssh')

    Register-ArgumentCompleter -CommandName $sshCommands    -ParameterName Target     -ScriptBlock $serverCompleter
    Register-ArgumentCompleter -CommandName $tunnelCommands -ParameterName RemotePort -ScriptBlock $dbPortCompleter
}
