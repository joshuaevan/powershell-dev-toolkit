#Requires -Version 5.1
<#
.SYNOPSIS
    Runs the full Pester test suite for PowerShellDevToolkit.
.DESCRIPTION
    Installs Pester 5+ if not present, then runs all tests under .\tests\
    with detailed output. Exit code mirrors the Pester result (0 = pass).
.EXAMPLE
    .\Invoke-Tests.ps1
#>

$ErrorActionPreference = 'Stop'

if (-not (Get-Module -ListAvailable -Name Pester | Where-Object { $_.Version -ge '5.0' })) {
    Write-Host "Pester 5+ not found. Installing from PSGallery..." -ForegroundColor Yellow
    Install-Module -Name Pester -MinimumVersion 5.0.0 -Force -Scope CurrentUser -SkipPublisherCheck
}

Import-Module Pester -MinimumVersion 5.0.0

$config = New-PesterConfiguration
$config.Run.Path         = Join-Path $PSScriptRoot 'tests'
$config.Run.Exit         = $true
$config.Output.Verbosity = 'Detailed'

Invoke-Pester -Configuration $config
