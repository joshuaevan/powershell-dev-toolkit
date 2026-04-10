@{
    RootModule        = 'PowerShellDevToolkit.psm1'
    ModuleVersion     = '1.1.0'
    GUID              = '882e07c2-69ad-46e6-aea6-07adb025f6b3'
    Author            = 'PowerShell Dev Toolkit Contributors'
    CompanyName       = 'Community'
    Copyright         = '(c) 2025 PowerShell Dev Toolkit Contributors. All rights reserved.'
    Description       = 'A comprehensive collection of PowerShell productivity tools for Windows developers. SSH tunneling, project management, AI integration, dev servers, and more.'

    PowerShellVersion = '5.1'

    FunctionsToExport = @(
        'Connect-SSH'
        'Connect-SSHTunnel'
        'Copy-ToClipboard'
        'Find-InProject'
        'Get-GitQuick'
        'Get-PortProcess'
        'Get-ProjectContext'
        'Get-ProjectInfo'
        'Get-ServiceStatus'
        'Invoke-Artisan'
        'Invoke-QuickRequest'
        'New-AIRules'
        'Set-ProjectEnv'
        'Show-Help'
        'Show-RecentCommands'
        'Start-DevServer'
        'Watch-LogFile'
    )

    CmdletsToExport   = @()
    VariablesToExport  = @()

    AliasesToExport   = @(
        'cssh'
        'tunnel'
        'tssh'
        'gs'
        'serve'
        'port'
        'search'
        'tail'
        'context'
        'proj'
        'art'
        'http'
        'useenv'
        'services'
        'clip'
        'ai-rules'
        'rc'
        'helpme'
    )

    PrivateData = @{
        PSData = @{
            Tags       = @('Windows', 'Developer', 'Productivity', 'SSH', 'DevTools')
            LicenseUri = 'https://github.com/joshuaevan/powershell-dev-toolkit/blob/main/LICENSE'
            ProjectUri = 'https://github.com/joshuaevan/powershell-dev-toolkit'
        }
    }
}
