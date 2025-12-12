<#
.SYNOPSIS
    Find or kill processes using a specific port.

.DESCRIPTION
    Shows what process is using a port, optionally kills it.
    Can also list all listening ports.

.PARAMETER Port
    The port number to check.

.PARAMETER Kill
    Kill the process using the port.

.PARAMETER List
    List all listening ports.

.PARAMETER AsJson
    Output as JSON for MCP tools.

.EXAMPLE
    port 3000           # Show what's using port 3000
    port 3000 -Kill     # Kill the process on port 3000
    port -List          # List all listening ports
    port 3000 -AsJson   # JSON output
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Position = 0)]
    [int]$Port,

    [switch]$Kill,
    [switch]$List,
    [switch]$AsJson
)

function Get-PortInfo {
    param([int]$TargetPort)
    
    $connections = Get-NetTCPConnection -LocalPort $TargetPort -ErrorAction SilentlyContinue |
        Where-Object { $_.State -eq 'Listen' -or $_.State -eq 'Established' }
    
    if (-not $connections) { return $null }
    
    $results = @()
    foreach ($conn in $connections) {
        $process = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
        $results += [ordered]@{
            port = $conn.LocalPort
            pid = $conn.OwningProcess
            process = $process.ProcessName
            path = $process.Path
            state = $conn.State
            localAddress = $conn.LocalAddress
        }
    }
    
    return $results
}

function Get-AllListeningPorts {
    $connections = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
        Sort-Object LocalPort
    
    $results = @()
    $seen = @{}
    
    foreach ($conn in $connections) {
        $key = "$($conn.LocalPort)-$($conn.OwningProcess)"
        if ($seen[$key]) { continue }
        $seen[$key] = $true
        
        $process = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
        $results += [ordered]@{
            port = $conn.LocalPort
            pid = $conn.OwningProcess
            process = $process.ProcessName
            localAddress = $conn.LocalAddress
        }
    }
    
    return $results
}

# List all listening ports
if ($List) {
    $ports = Get-AllListeningPorts
    
    if ($AsJson) {
        $ports | ConvertTo-Json -Depth 5
        exit 0
    }
    
    Write-Host ""
    Write-Host "Listening Ports" -ForegroundColor Cyan
    Write-Host "===============" -ForegroundColor Cyan
    Write-Host ""
    
    $ports | ForEach-Object {
        Write-Host "  " -NoNewline
        Write-Host "$($_.port.ToString().PadRight(6))" -ForegroundColor Yellow -NoNewline
        Write-Host " $($_.process.PadRight(20))" -ForegroundColor White -NoNewline
        Write-Host " (PID: $($_.pid))" -ForegroundColor DarkGray
    }
    Write-Host ""
    exit 0
}

# Require port for other operations
if (-not $Port) {
    Write-Host "Usage: port <number> [-Kill] [-List] [-AsJson]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  port 3000        # Show what's using port 3000"
    Write-Host "  port 3000 -Kill  # Kill the process"
    Write-Host "  port -List       # Show all listening ports"
    exit 1
}

# Get port info
$info = Get-PortInfo -TargetPort $Port

if (-not $info) {
    if ($AsJson) {
        @{ port = $Port; status = 'free'; process = $null } | ConvertTo-Json
    } else {
        Write-Host ""
        Write-Host "Port $Port is " -NoNewline
        Write-Host "free" -ForegroundColor Green
        Write-Host ""
    }
    exit 0
}

# Kill process if requested
if ($Kill) {
    foreach ($item in $info) {
        if ($PSCmdlet.ShouldProcess("$($item.process) (PID: $($item.pid))", "Kill")) {
            try {
                Stop-Process -Id $item.pid -Force -ErrorAction Stop
                if ($AsJson) {
                    @{ port = $Port; status = 'killed'; pid = $item.pid; process = $item.process } | ConvertTo-Json
                } else {
                    Write-Host ""
                    Write-Host "Killed " -NoNewline -ForegroundColor Green
                    Write-Host "$($item.process)" -NoNewline -ForegroundColor Yellow
                    Write-Host " (PID: $($item.pid)) on port $Port" -ForegroundColor Green
                    Write-Host ""
                }
            } catch {
                if ($AsJson) {
                    @{ port = $Port; status = 'error'; error = $_.Exception.Message } | ConvertTo-Json
                } else {
                    Write-Host "Failed to kill process: $($_.Exception.Message)" -ForegroundColor Red
                }
                exit 1
            }
        }
    }
    exit 0
}

# Display port info
if ($AsJson) {
    @{ port = $Port; status = 'in_use'; processes = $info } | ConvertTo-Json -Depth 5
    exit 0
}

Write-Host ""
Write-Host "Port $Port is " -NoNewline
Write-Host "in use" -ForegroundColor Red
Write-Host ""

foreach ($item in $info) {
    Write-Host "  Process: " -NoNewline -ForegroundColor Cyan
    Write-Host $item.process -ForegroundColor Yellow
    Write-Host "  PID:     " -NoNewline -ForegroundColor Cyan
    Write-Host $item.pid -ForegroundColor White
    Write-Host "  State:   " -NoNewline -ForegroundColor Cyan
    Write-Host $item.state -ForegroundColor White
    if ($item.path) {
        Write-Host "  Path:    " -NoNewline -ForegroundColor Cyan
        Write-Host $item.path -ForegroundColor DarkGray
    }
    Write-Host ""
}

Write-Host "Run " -NoNewline -ForegroundColor Gray
Write-Host "port $Port -Kill" -NoNewline -ForegroundColor Yellow
Write-Host " to terminate" -ForegroundColor Gray
Write-Host ""
