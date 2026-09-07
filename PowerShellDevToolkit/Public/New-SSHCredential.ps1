function New-SSHCredential {
    <#
    .SYNOPSIS
        Store SSH credentials for Connect-SSH and Connect-SSHTunnel.

    .DESCRIPTION
        Prompts for a username and password and saves them, encrypted with
        Windows DPAPI, to the toolkit creds folder (see Get-ToolkitPaths).
        The file can only be decrypted by your Windows account on this machine.

    .PARAMETER UserName
        Pre-fill the username in the credential prompt.

    .PARAMETER Credential
        Supply a PSCredential directly instead of prompting.

    .PARAMETER FileName
        Credential file name. Defaults to ssh.credentialFile from config.json,
        or ssh-credentials.xml when not configured.

    .PARAMETER Force
        Overwrite an existing credential file.

    .EXAMPLE
        New-SSHCredential
    .EXAMPLE
        New-SSHCredential -UserName deploy
    .EXAMPLE
        New-SSHCredential -UserName prod-user -FileName prod-credentials.xml
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$UserName,

        [System.Management.Automation.PSCredential]$Credential,

        [string]$FileName,

        [switch]$Force
    )

    $paths = Get-ToolkitPaths

    if (-not $FileName) {
        $config = Get-ScriptConfig -Quiet
        if ($config -and $config.ssh -and $config.ssh.credentialFile) {
            $FileName = $config.ssh.credentialFile
        } else {
            $FileName = 'ssh-credentials.xml'
        }
    }

    if (-not (Test-Path $paths.CredsPath)) {
        New-Item -Path $paths.CredsPath -ItemType Directory -Force | Out-Null
    }

    $target = Join-Path $paths.CredsPath $FileName

    if ((Test-Path $target) -and -not $Force) {
        Write-Host "Credential file already exists: $target" -ForegroundColor Yellow
        Write-Host "Use -Force to overwrite it." -ForegroundColor Gray
        return
    }

    if (-not $Credential) {
        $promptArgs = @{ Message = 'Enter your SSH username and password' }
        if ($UserName) { $promptArgs.UserName = $UserName }
        $Credential = Get-Credential @promptArgs
        if (-not $Credential) {
            Write-Host "Cancelled. No credential file written." -ForegroundColor Yellow
            return
        }
    }

    $Credential | Export-Clixml -Path $target

    Write-Host ""
    Write-Host "Saved credentials for " -NoNewline -ForegroundColor Green
    Write-Host $Credential.UserName -NoNewline -ForegroundColor Yellow
    Write-Host " to:" -ForegroundColor Green
    Write-Host "  $target" -ForegroundColor White
    Write-Host ""
    Write-Host "The file is encrypted with Windows DPAPI and can only be read by your account on this machine." -ForegroundColor Gray
    Write-Host ""
}
