# PowerShellDevToolkit Root Module
# Repo root is one level above the module folder
$script:ToolkitRoot = Split-Path $PSScriptRoot

# Dot-source private functions first, then public
$Private = @(Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -ErrorAction SilentlyContinue)
$Public  = @(Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1"  -ErrorAction SilentlyContinue)

foreach ($file in @($Private + $Public)) {
    try { . $file.FullName }
    catch { Write-Error "Failed to import $($file.FullName): $_" }
}

# Aliases
New-Alias -Name cssh      -Value Connect-SSH          -Force -Scope Global
New-Alias -Name tunnel    -Value Connect-SSHTunnel    -Force -Scope Global
New-Alias -Name tssh      -Value Connect-SSHTunnel    -Force -Scope Global
New-Alias -Name gs        -Value Get-GitQuick         -Force -Scope Global
New-Alias -Name serve     -Value Start-DevServer      -Force -Scope Global
New-Alias -Name port      -Value Get-PortProcess      -Force -Scope Global
New-Alias -Name search    -Value Find-InProject       -Force -Scope Global
New-Alias -Name tail      -Value Watch-LogFile        -Force -Scope Global
New-Alias -Name context   -Value Get-ProjectContext   -Force -Scope Global
New-Alias -Name proj      -Value Get-ProjectInfo      -Force -Scope Global
New-Alias -Name art       -Value Invoke-Artisan       -Force -Scope Global
New-Alias -Name http      -Value Invoke-QuickRequest  -Force -Scope Global
New-Alias -Name useenv    -Value Set-ProjectEnv       -Force -Scope Global
New-Alias -Name services  -Value Get-ServiceStatus    -Force -Scope Global
New-Alias -Name clip      -Value Copy-ToClipboard     -Force -Scope Global
New-Alias -Name ai-rules  -Value New-AIRules          -Force -Scope Global
New-Alias -Name rc        -Value Show-RecentCommands  -Force -Scope Global
New-Alias -Name helpme    -Value Show-Help            -Force -Scope Global
