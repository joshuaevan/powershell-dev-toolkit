<#
.SYNOPSIS
    Setup and verify environment for PowerShell scripts collection.

.DESCRIPTION
    This script checks for all required dependencies and guides you through
    setting up your environment to use the PowerShell scripts collection.
    
    It will check for:
    - PowerShell version
    - Git
    - WSL and sshpass (for SSH features)
    - Posh-SSH module (fallback for SSH)
    - Development tools (Node.js, PHP, Python, Perl, Composer)
    - Notepad++ (for editing features)
    
    And optionally:
    - Add scripts to PATH
    - Configure PowerShell profile with aliases
    - Install missing PowerShell modules
    - Set up WSL sshpass

.PARAMETER SkipOptional
    Skip checking optional dependencies (only check essential ones).

.PARAMETER InstallModules
    Automatically install missing PowerShell modules.

.PARAMETER UpdateProfile
    Automatically update PowerShell profile with aliases.

.PARAMETER Force
    Force reinstallation/reconfiguration.

.EXAMPLE
    .\Setup-Environment.ps1
    
.EXAMPLE
    .\Setup-Environment.ps1 -InstallModules -UpdateProfile

.EXAMPLE
    .\Setup-Environment.ps1 -SkipOptional
#>

[CmdletBinding()]
param(
    [switch]$SkipOptional,
    [switch]$InstallModules,
    [switch]$UpdateProfile,
    [switch]$Force
)

$ErrorActionPreference = 'Continue'

# Color helper functions
function Write-Status { param([string]$Text) Write-Host $Text -ForegroundColor Cyan }
function Write-Success { param([string]$Text) Write-Host "[OK] $Text" -ForegroundColor Green }
function Write-Warn { param([string]$Text) Write-Host "[WARN] $Text" -ForegroundColor Yellow }
function Write-Failure { param([string]$Text) Write-Host "[FAIL] $Text" -ForegroundColor Red }
function Write-Info { param([string]$Text) Write-Host "  $Text" -ForegroundColor Gray }

# Results tracking
$results = @{
    Essential = @()
    Optional = @()
    DevTools = @()
    Missing = @()
    Warnings = @()
}

Clear-Host
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  PowerShell Scripts Environment Setup" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Status "Checking environment dependencies..."
Write-Host ""

# ============================================================================
# ESSENTIAL CHECKS
# ============================================================================

Write-Host "ESSENTIAL COMPONENTS:" -ForegroundColor Yellow
Write-Host ""

# PowerShell Version
Write-Host "  PowerShell Version... " -NoNewline
$psVersion = $PSVersionTable.PSVersion
if ($psVersion.Major -ge 5) {
    Write-Success "v$($psVersion.Major).$($psVersion.Minor) (OK)"
    $results.Essential += "PowerShell $psVersion"
} else {
    Write-Failure "v$($psVersion.Major).$($psVersion.Minor) (Too old, need 5.1+)"
    $results.Missing += "PowerShell 5.1 or higher"
}

# Git
Write-Host "  Git..................  " -NoNewline
$git = Get-Command git -ErrorAction SilentlyContinue
if ($git) {
    $gitVersion = (git --version) -replace 'git version ', ''
    Write-Success "$gitVersion"
    $results.Essential += "Git $gitVersion"
} else {
    Write-Failure "Not found"
    $results.Missing += "Git"
    Write-Info "    Download from: https://git-scm.com/download/win"
}

# Scripts Directory
Write-Host "  Scripts Directory....  " -NoNewline
if (Test-Path $scriptDir) {
    Write-Success "$scriptDir"
    $results.Essential += "Scripts directory"
} else {
    Write-Failure "Not found"
    $results.Missing += "Scripts directory"
}

Write-Host ""

# ============================================================================
# SSH TOOLS
# ============================================================================

Write-Host "SSH TOOLS (for Connect-SSH & Connect-SSHTunnel):" -ForegroundColor Yellow
Write-Host ""

# WSL
Write-Host "  WSL..................  " -NoNewline
$wsl = Get-Command wsl -ErrorAction SilentlyContinue
$hasSshpass = $null
if ($wsl) {
    try {
        $wslVersion = wsl --version 2>&1
        if ($wslVersion -match 'WSL version') {
            $version = ($wslVersion | Select-String -Pattern 'WSL version: (.+)').Matches.Groups[1].Value
            Write-Success "v$version"
            $results.Optional += "WSL $version"
            
            # Check for sshpass in WSL
            Write-Host "  sshpass (in WSL).....  " -NoNewline
            $hasSshpass = wsl bash -c "command -v sshpass >/dev/null 2>&1 && echo 'yes' || echo 'no'" 2>$null
            if ($hasSshpass -match 'yes') {
                Write-Success "Installed"
                $results.Optional += "sshpass (WSL)"
            } else {
                Write-Warn "Not installed"
                $results.Warnings += "sshpass (WSL) - can auto-install on first use"
                Write-Info "    Will be installed automatically on first SSH connection"
            }
        } else {
            Write-Success "Installed"
            $results.Optional += "WSL"
        }
    } catch {
        Write-Warn "Installed but not configured"
        Write-Info "    Run 'wsl --install' and restart"
    }
} else {
    Write-Warn "Not installed"
    $results.Warnings += "WSL - SSH features will use Posh-SSH instead"
    Write-Info "    Optional but recommended. Install with: wsl --install"
}

# Posh-SSH Module (fallback)
Write-Host "  Posh-SSH Module......  " -NoNewline
$poshSSH = Get-Module -ListAvailable -Name Posh-SSH -ErrorAction SilentlyContinue
if ($poshSSH) {
    Write-Success "v$($poshSSH.Version) (Installed)"
    $results.Optional += "Posh-SSH $($poshSSH.Version)"
} else {
    if (-not $wsl) {
        Write-Warn "Not installed (fallback for SSH without WSL)"
        $results.Warnings += "Posh-SSH - needed if WSL not available"
        Write-Info "    Install with: Install-Module -Name Posh-SSH -Scope CurrentUser"
        
        if ($InstallModules) {
            Write-Host ""
            Write-Info "    Installing Posh-SSH module..."
            try {
                Install-Module -Name Posh-SSH -Scope CurrentUser -Force -ErrorAction Stop
                Write-Success "Posh-SSH installed successfully"
                $results.Optional += "Posh-SSH (newly installed)"
            } catch {
                Write-Failure "Failed to install Posh-SSH: $($_.Exception.Message)"
            }
        }
    } else {
        Write-Info "Not installed (WSL available, not needed)"
    }
}

# SSH Credentials Directory
Write-Host "  Credentials Dir......  " -NoNewline
$credsDir = Join-Path $scriptDir "creds"
if (Test-Path $credsDir) {
    Write-Success "$credsDir"
    $results.Optional += "Credentials directory"
} else {
    Write-Warn "Not found - creating..."
    try {
        New-Item -Path $credsDir -ItemType Directory -Force | Out-Null
        Write-Success "Created $credsDir"
        $results.Optional += "Credentials directory (created)"
    } catch {
        Write-Failure "Failed to create credentials directory"
        $results.Missing += "Credentials directory"
    }
}

Write-Host ""

# ============================================================================
# DEVELOPMENT TOOLS (Optional)
# ============================================================================

if (-not $SkipOptional) {
    Write-Host "DEVELOPMENT TOOLS (Optional, as needed):" -ForegroundColor Yellow
    Write-Host ""
    
    # Node.js & npm
    Write-Host "  Node.js & npm........  " -NoNewline
    $node = Get-Command node -ErrorAction SilentlyContinue
    $npm = Get-Command npm -ErrorAction SilentlyContinue
    if ($node -and $npm) {
        $nodeVersion = (node --version) -replace 'v', ''
        $npmVersion = (npm --version)
        Write-Success "Node $nodeVersion, npm $npmVersion"
        $results.DevTools += "Node.js $nodeVersion"
    } else {
        Write-Info "Not installed"
        Write-Info "    Needed for: JavaScript/Node projects"
        Write-Info "    Download from: https://nodejs.org/"
    }
    
    # PHP
    Write-Host "  PHP..................  " -NoNewline
    $php = Get-Command php -ErrorAction SilentlyContinue
    if ($php) {
        $phpVersion = (php -v 2>$null | Select-Object -First 1) -replace 'PHP ', '' -replace ' \(.*', ''
        Write-Success "$phpVersion"
        $results.DevTools += "PHP $phpVersion"
    } else {
        Write-Info "Not installed"
        Write-Info "    Needed for: PHP/Laravel projects"
        Write-Info "    Download from: https://windows.php.net/download/"
    }
    
    # Composer
    Write-Host "  Composer.............  " -NoNewline
    $composer = Get-Command composer -ErrorAction SilentlyContinue
    if ($composer) {
        $composerVersion = (composer --version 2>$null | Select-String -Pattern 'Composer version (\S+)').Matches.Groups[1].Value
        Write-Success "$composerVersion"
        $results.DevTools += "Composer $composerVersion"
    } else {
        Write-Info "Not installed"
        Write-Info "    Needed for: PHP dependency management"
        Write-Info "    Download from: https://getcomposer.org/"
    }
    
    # Python
    Write-Host "  Python...............  " -NoNewline
    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($python) {
        $pythonVersion = (python --version 2>&1) -replace 'Python ', ''
        Write-Success "$pythonVersion"
        $results.DevTools += "Python $pythonVersion"
        
        # Pip
        Write-Host "  pip..................  " -NoNewline
        $pip = Get-Command pip -ErrorAction SilentlyContinue
        if ($pip) {
            $pipVersion = (pip --version) -replace 'pip ', '' -replace ' from.*', ''
            Write-Success "$pipVersion"
            $results.DevTools += "pip $pipVersion"
        } else {
            Write-Info "Not installed"
        }
    } else {
        Write-Info "Not installed"
        Write-Info "    Needed for: Python projects"
        Write-Info "    Download from: https://www.python.org/downloads/"
    }
    
    # Perl
    Write-Host "  Perl.................  " -NoNewline
    $perl = Get-Command perl -ErrorAction SilentlyContinue
    if ($perl) {
        $perlVersion = (perl --version | Select-String -Pattern 'v(\d+\.\d+\.\d+)').Matches.Groups[1].Value
        Write-Success "$perlVersion"
        $results.DevTools += "Perl $perlVersion"
    } else {
        Write-Info "Not installed"
        Write-Info "    Needed for: Perl projects"
        Write-Info "    Download from: https://strawberryperl.com/"
    }
    
    Write-Host ""
}

# ============================================================================
# EDITOR INTEGRATION
# ============================================================================

if (-not $SkipOptional) {
    Write-Host "EDITOR INTEGRATION:" -ForegroundColor Yellow
    Write-Host ""
    
    # Notepad++
    Write-Host "  Notepad++............  " -NoNewline
    $npp = Get-Command notepad++ -ErrorAction SilentlyContinue
    if (-not $npp) {
        # Check common install locations
        $nppPaths = @(
            "${env:ProgramFiles}\Notepad++\notepad++.exe",
            "${env:ProgramFiles(x86)}\Notepad++\notepad++.exe"
        )
        foreach ($path in $nppPaths) {
            if (Test-Path $path) {
                $npp = $path
                break
            }
        }
    }
    
    if ($npp) {
        Write-Success "Installed"
        $results.Optional += "Notepad++"
    } else {
        Write-Info "Not installed"
        Write-Info "    Needed for: Quick file editing (e, npp commands)"
        Write-Info "    Download from: https://notepad-plus-plus.org/"
    }
    
    Write-Host ""
}

# ============================================================================
# PATH CONFIGURATION
# ============================================================================

Write-Host "PATH CONFIGURATION:" -ForegroundColor Yellow
Write-Host ""

Write-Host "  Scripts in PATH......  " -NoNewline
$pathEntries = $env:Path -split ';'
$scriptsInPath = $pathEntries -contains $scriptDir

if ($scriptsInPath) {
    Write-Success "Yes"
} else {
    Write-Warn "No"
    $results.Warnings += "Scripts directory not in PATH"
    Write-Info "    Add to PATH to run scripts from anywhere (examples use c:\powershell-dev-toolkit)"
    Write-Info "    Current PowerShell session: `$env:Path += ';$scriptDir'"
    Write-Info "    Permanent (User): [System.Environment]::SetEnvironmentVariable('Path', [System.Environment]::GetEnvironmentVariable('Path','User') + ';$scriptDir', 'User')"
}

Write-Host ""

# ============================================================================
# POWERSHELL PROFILE
# ============================================================================

Write-Host "POWERSHELL PROFILE:" -ForegroundColor Yellow
Write-Host ""

Write-Host "  Profile exists.......  " -NoNewline
$profileExists = Test-Path $PROFILE
if ($profileExists) {
    Write-Success "Yes ($PROFILE)"
} else {
    Write-Warn "No"
    Write-Info "    Will be created if you choose to update profile"
}

Write-Host "  Profile configured...  " -NoNewline
$hasScripts = $false
if ($profileExists) {
    $profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
    $hasScripts = $profileContent -match 'Connect-SSH|Get-GitQuick|Start-DevServer'
    
    if ($hasScripts) {
        Write-Success "Yes (aliases configured)"
        $results.Optional += "PowerShell profile configured"
    } else {
        Write-Warn "Not configured"
        $results.Warnings += "PowerShell profile - aliases not set up"
    }
} else {
    Write-Warn "No profile file"
    $results.Warnings += "PowerShell profile - needs creation"
}

Write-Host ""

# ============================================================================
# SUMMARY
# ============================================================================

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  SUMMARY" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

if ($results.Essential.Count -gt 0) {
    Write-Host "Essential Components: " -NoNewline -ForegroundColor Green
    Write-Host "$($results.Essential.Count) installed" -ForegroundColor White
}

if ($results.Optional.Count -gt 0) {
    Write-Host "Optional Components:  " -NoNewline -ForegroundColor Cyan
    Write-Host "$($results.Optional.Count) available" -ForegroundColor White
}

if ($results.DevTools.Count -gt 0) {
    Write-Host "Development Tools:    " -NoNewline -ForegroundColor Cyan
    Write-Host "$($results.DevTools.Count) installed" -ForegroundColor White
}

if ($results.Missing.Count -gt 0) {
    Write-Host ""
    Write-Host "MISSING (Critical):" -ForegroundColor Red
    foreach ($item in $results.Missing) {
        Write-Host "  [FAIL] $item" -ForegroundColor Red
    }
}

if ($results.Warnings.Count -gt 0) {
    Write-Host ""
    Write-Host "WARNINGS (Optional):" -ForegroundColor Yellow
    foreach ($item in $results.Warnings) {
        Write-Host "  [WARN] $item" -ForegroundColor Yellow
    }
}

Write-Host ""

# ============================================================================
# CONFIGURATION OPTIONS
# ============================================================================

$needsConfiguration = $results.Warnings.Count -gt 0 -or $results.Missing.Count -gt 0

if ($needsConfiguration) {
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  RECOMMENDED ACTIONS" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    # Profile setup
    if (-not $hasScripts -or $Force) {
        Write-Host "Would you like to update your PowerShell profile with script aliases?" -ForegroundColor Yellow
        Write-Host "  This will add aliases like: cssh, tunnel, gs, serve, port, search, etc." -ForegroundColor Gray
        Write-Host ""
        
        if ($UpdateProfile) {
            $updateProfileResponse = 'Y'
        } else {
            $updateProfileResponse = Read-Host "Update profile? (Y/N)"
        }
        
        if ($updateProfileResponse -eq 'Y' -or $updateProfileResponse -eq 'y') {
            Write-Host ""
            Write-Info "Updating PowerShell profile..."
            
            # Create profile if it doesn't exist
            if (-not $profileExists) {
                New-Item -Path $PROFILE -ItemType File -Force | Out-Null
                Write-Success "Created profile file: $PROFILE"
            }
            
            # Backup existing profile
            if ($profileExists) {
                $backupPath = "$PROFILE.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
                Copy-Item $PROFILE $backupPath -Force
                Write-Success "Backed up existing profile to: $backupPath"
            }
            
            # Generate profile content
            $profileAddition = @"

# ═══════════════════════════════════════════════════════════
# PowerShell Scripts Collection
# Generated by Setup-Environment.ps1 on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
# ═══════════════════════════════════════════════════════════

# Add scripts directory to PATH
`$env:Path += ";$scriptDir"

# Script Aliases - SSH & Networking
Set-Alias -Name cssh -Value "$scriptDir\Connect-SSH.ps1"
Set-Alias -Name tunnel -Value "$scriptDir\Connect-SSHTunnel.ps1"
Set-Alias -Name tssh -Value "$scriptDir\Connect-SSHTunnel.ps1"

# Script Aliases - Development Tools
Set-Alias -Name gs -Value "$scriptDir\Get-GitQuick.ps1"
Set-Alias -Name serve -Value "$scriptDir\Start-DevServer.ps1"
Set-Alias -Name port -Value "$scriptDir\Get-PortProcess.ps1"
Set-Alias -Name search -Value "$scriptDir\Find-InProject.ps1"
Set-Alias -Name tail -Value "$scriptDir\Watch-LogFile.ps1"
Set-Alias -Name context -Value "$scriptDir\Get-ProjectContext.ps1"
Set-Alias -Name proj -Value "$scriptDir\Get-ProjectInfo.ps1"
Set-Alias -Name art -Value "$scriptDir\Invoke-Artisan.ps1"
Set-Alias -Name http -Value "$scriptDir\Invoke-QuickRequest.ps1"
Set-Alias -Name useenv -Value "$scriptDir\Set-ProjectEnv.ps1"
Set-Alias -Name services -Value "$scriptDir\Get-ServiceStatus.ps1"
Set-Alias -Name clip -Value "$scriptDir\Copy-ToClipboard.ps1"

# Script Aliases - AI & Utilities
Set-Alias -Name ai-rules -Value "$scriptDir\New-AIRules.ps1"
Set-Alias -Name rc -Value "$scriptDir\recent-commands.ps1"
Set-Alias -Name helpme -Value "$scriptDir\helpme.ps1"

# Quick reload function
function reload { . `$PROFILE }

Write-Host "PowerShell Scripts Collection loaded. Type " -NoNewline
Write-Host "helpme" -ForegroundColor Yellow -NoNewline
Write-Host " for command reference."

"@
            
            # Append to profile
            Add-Content -Path $PROFILE -Value $profileAddition
            Write-Success "Profile updated successfully!"
            Write-Host ""
            Write-Host "  Reload your profile to use the new aliases:" -ForegroundColor Cyan
            Write-Host "    . `$PROFILE" -ForegroundColor Yellow
            Write-Host "    or just type: reload" -ForegroundColor Yellow
            Write-Host ""
        }
    }
    
    # SSH credentials setup
    if (-not (Test-Path "$credsDir\*.xml")) {
        Write-Host ""
        Write-Host "SSH CREDENTIALS SETUP:" -ForegroundColor Yellow
        Write-Host "  To use SSH commands (cssh, tunnel), you need to store credentials." -ForegroundColor Gray
        Write-Host ""
        Write-Host "  Run these commands to set up credentials:" -ForegroundColor Cyan
        Write-Host "    # First, make sure you have config.json set up (copy from config.example.json)" -ForegroundColor Gray
        Write-Host "    `$cred = Get-Credential -UserName 'your-ssh-username'" -ForegroundColor Yellow
        Write-Host "    `$cred | Export-Clixml '$credsDir\ssh-credentials.xml'" -ForegroundColor Yellow
        Write-Host ""
    }
    
    # WSL sshpass setup
    if ($wsl -and $hasSshpass -notmatch 'yes') {
        Write-Host ""
        Write-Host "WSL SSHPASS SETUP:" -ForegroundColor Yellow
        Write-Host "  sshpass will be installed automatically on first SSH connection." -ForegroundColor Gray
        Write-Host "  Or install now with:" -ForegroundColor Cyan
        Write-Host "    wsl bash -c 'sudo apt-get update && sudo apt-get install -y sshpass'" -ForegroundColor Yellow
        Write-Host ""
    }
}

# ============================================================================
# COMPLETION
# ============================================================================

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

if ($results.Missing.Count -eq 0) {
    Write-Success "Setup complete! Your environment is ready."
} else {
    Write-Warn "Setup complete with warnings. Install missing components as needed."
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Install any missing essential tools" -ForegroundColor White
Write-Host "  2. Reload your PowerShell profile: " -NoNewline -ForegroundColor White
Write-Host ". `$PROFILE" -ForegroundColor Yellow
Write-Host "  3. Run " -NoNewline -ForegroundColor White
Write-Host "helpme" -NoNewline -ForegroundColor Yellow
Write-Host " to see all available commands" -ForegroundColor White
Write-Host ""
Write-Host "For more information, see: $scriptDir\README.md" -ForegroundColor Gray
Write-Host ""
