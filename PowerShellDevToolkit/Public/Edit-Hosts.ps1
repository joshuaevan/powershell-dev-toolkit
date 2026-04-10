function Edit-Hosts {
    <#
    .SYNOPSIS
        Open the Windows hosts file in an elevated editor session.

    .DESCRIPTION
        Launches Notepad++ (or notepad.exe) with administrator privileges to
        edit C:\Windows\System32\drivers\etc\hosts.

    .EXAMPLE
        Edit-Hosts
    #>
    [CmdletBinding()]
    param()

    $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"

    $nppExe = $null
    $config = Get-ScriptConfig -ErrorAction SilentlyContinue
    if ($config -and $config.editor -and $config.editor.notepadPlusPlus) {
        if (Test-Path $config.editor.notepadPlusPlus) {
            $nppExe = $config.editor.notepadPlusPlus
        }
    }

    if (-not $nppExe) {
        $candidates = @(
            "${env:ProgramFiles}\Notepad++\notepad++.exe",
            "${env:ProgramFiles(x86)}\Notepad++\notepad++.exe",
            "${env:LOCALAPPDATA}\Programs\Notepad++\notepad++.exe"
        )
        foreach ($c in $candidates) {
            if (Test-Path $c) { $nppExe = $c; break }
        }
    }

    if (-not $nppExe) {
        $cmd = Get-Command 'notepad++' -ErrorAction SilentlyContinue
        if ($cmd) { $nppExe = $cmd.Source }
    }

    $editor = if ($nppExe) { $nppExe } else { 'notepad.exe' }

    Write-Host "Opening hosts file with elevated privileges..." -ForegroundColor Cyan
    Start-Process -FilePath $editor -ArgumentList "`"$hostsPath`"" -Verb RunAs
}
