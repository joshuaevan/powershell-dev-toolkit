function Test-WslAvailable {
    <#
    .SYNOPSIS
        Return $true when WSL is installed and a distribution responds.
    #>
    [CmdletBinding()]
    param()

    if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) { return $false }
    $wslCheck = wsl echo "ok" 2>&1
    return [bool]($wslCheck -eq "ok")
}
