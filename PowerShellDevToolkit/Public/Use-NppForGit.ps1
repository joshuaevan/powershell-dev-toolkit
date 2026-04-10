function Use-NppForGit {
    <#
    .SYNOPSIS
        Configure Git to use Notepad++ as its default editor.

    .DESCRIPTION
        Sets git config --global core.editor to the Notepad++ executable path.
        Reads the path from config.json (editor.notepadPlusPlus) or auto-detects
        it from common install locations.

    .EXAMPLE
        Use-NppForGit
    #>
    [CmdletBinding()]
    param()

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

    if (-not $nppExe) {
        Write-Error "Notepad++ not found. Install it or set editor.notepadPlusPlus in config.json."
        return
    }

    $escaped = $nppExe -replace '\\', '/'
    git config --global core.editor "`"$escaped`" -multiInst -notabbar -nosession -noPlugin"
    Write-Host "Git editor set to: $nppExe" -ForegroundColor Green
}
