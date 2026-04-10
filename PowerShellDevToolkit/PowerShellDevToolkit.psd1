@{
    RootModule        = 'PowerShellDevToolkit.psm1'
    ModuleVersion     = '1.2.0'
    GUID              = '882e07c2-69ad-46e6-aea6-07adb025f6b3'
    Author            = 'PowerShell Dev Toolkit Contributors'
    CompanyName       = 'Community'
    Copyright         = '(c) 2025 PowerShell Dev Toolkit Contributors. All rights reserved.'
    Description       = 'A comprehensive collection of PowerShell productivity tools for Windows developers. SSH tunneling, project management, AI integration, dev servers, and more.'

    PowerShellVersion = '5.1'

    FunctionsToExport = @(
        # Original commands
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
        # File & editor commands
        'Edit-File'
        'Edit-Profile'
        'Edit-Hosts'
        'Use-NppForGit'
        'Set-FileTimestamp'
        'Open-Item'
        # Directory commands
        'Get-DirectoryListing'
        'New-DirectoryAndEnter'
        'Set-TempLocation'
        # Utility commands
        'Get-CommandLocation'
        'Invoke-Elevated'
        'Add-Path'
        'Invoke-ProfileReload'
        # Network commands
        'Get-IPAddress'
        'Clear-DNSCache'
        # Toolkit management
        'Update-Toolkit'
        'Test-ToolkitUpdate'
    )

    CmdletsToExport   = @()
    VariablesToExport  = @()

    AliasesToExport   = @(
        # Original aliases
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
        # File & editor aliases
        'e'
        'npp'
        'touch'
        'open'
        # Directory aliases
        'll'
        'mkcd'
        'temp'
        # Utility aliases
        'which'
        'sudo'
        'reload'
        'grep'
        # Network aliases
        'ip'
        'Flush-DNS'
    )

    PrivateData = @{
        PSData = @{
            Tags       = @('Windows', 'Developer', 'Productivity', 'SSH', 'DevTools')
            LicenseUri = 'https://github.com/joshuaevan/powershell-dev-toolkit/blob/main/LICENSE'
            ProjectUri = 'https://github.com/joshuaevan/powershell-dev-toolkit'
        }
    }
}
