function Edit-File {
    <#
    .SYNOPSIS
        Open a file or folder in the configured editor (defaults to Notepad++).

    .DESCRIPTION
        Opens the specified path in Notepad++, using the path from config.json
        (editor.notepadPlusPlus). Falls back to common install locations, then
        to notepad.exe if Notepad++ is not found. When no path is given, opens
        the current directory.

    .PARAMETER Path
        File or folder to open. Defaults to the current directory.

    .PARAMETER Line
        Jump to this line number (Notepad++ only).

    .PARAMETER Column
        Jump to this column number (Notepad++ only, requires -Line).

    .EXAMPLE
        Edit-File .\file.ps1
        Edit-File .\file.ps1 -Line 42 -Column 1
        Edit-File .
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Path = '.',

        [Parameter()]
        [int]$Line,

        [Parameter()]
        [int]$Column
    )

    $resolvedPath = Resolve-Path $Path -ErrorAction SilentlyContinue
    if (-not $resolvedPath) {
        Write-Error "Path not found: $Path"
        return
    }

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

    if ($nppExe) {
        $args = @("`"$resolvedPath`"")
        if ($Line -gt 0) { $args += "-n$Line" }
        if ($Column -gt 0) { $args += "-c$Column" }
        Start-Process -FilePath $nppExe -ArgumentList $args
    } else {
        Write-Warning "Notepad++ not found. Falling back to notepad.exe."
        Start-Process notepad.exe -ArgumentList "`"$resolvedPath`""
    }
}
