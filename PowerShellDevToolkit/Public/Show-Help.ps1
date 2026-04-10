function Show-Help {
    <#
    .SYNOPSIS
        Quick reference for your PowerShell shortcuts and commands.

    .PARAMETER ProfileOnly
        Show only profile-related commands.

    .PARAMETER ScriptsOnly
        Show only script-related commands.

    .EXAMPLE
        Show-Help
        helpme
    #>
    [CmdletBinding()]
    param(
        [switch]$ProfileOnly,
        [switch]$ScriptsOnly
    )

    function Write-Header { param([string]$Text) Write-Host "`n$Text" -ForegroundColor Cyan -BackgroundColor DarkBlue }
    function Write-Cmd { param([string]$Cmd, [string]$Desc) Write-Host "  " -NoNewline; Write-Host $Cmd -ForegroundColor Yellow -NoNewline; Write-Host " - $Desc" }
    function Write-Option { param([string]$Text) Write-Host "    $Text" -ForegroundColor Gray }

    if (-not $ScriptsOnly) {
        Write-Header "FILE & EDITOR COMMANDS"
        Write-Cmd "e [Path] [-Line N] [-Column N]" "Edit file/folder in Notepad++ (defaults to current dir)"
        Write-Option "  e .\file.txt                    # Edit file"
        Write-Option "  e .\file.ps1 -Line 42 -Column 1 # Edit at specific line/column"
        Write-Option "  e .                             # Open current folder"
        Write-Cmd "npp" "Alias for 'e'"
        Write-Cmd "Edit-Profile" "Open PowerShell profile in Notepad++"
        Write-Cmd "Edit-Hosts" "Edit hosts file in Notepad++"
        Write-Cmd "Use-NppForGit" "Configure Git to use Notepad++ as editor"
        Write-Cmd "touch <Path>" "Create file or update its timestamp"
        Write-Cmd "open <Path>" "Open file/folder with default application"
        Write-Cmd "o." "Open current folder in Explorer"

        Write-Header "DIRECTORY COMMANDS"
        Write-Cmd "ll" "Enhanced directory listing (folders first, formatted table)"
        Write-Cmd "la" "List all files including hidden"
        Write-Cmd "mkcd <Path>" "Create directory and navigate into it"
        Write-Cmd "temp" "Navigate to temp directory (`$env:TEMP)"

        Write-Header "UTILITY COMMANDS"
        Write-Cmd "which <command>" "Find the location of a command"
        Write-Cmd "grep" "Alias for Select-String (search text in files)"
        Write-Cmd "sudo <command> [args]" "Run command as administrator"
        Write-Cmd "Add-Path <Path> [-User]" "Add directory to PATH (use -User for user PATH)"
        Write-Cmd "reload" "Reload PowerShell profile"
        Write-Cmd "recent-commands [-Count N] [-PageSize N] [-Page N] [-Interactive]" "Display recent unique PowerShell commands in paginated format"
        Write-Cmd "rc" "Short alias for recent-commands"
        Write-Option "  rc                          # Show first page (30 commands)"
        Write-Option "  rc -Interactive             # Interactive pagination mode"
        Write-Option "  rc -Page 2                  # Show page 2"
        Write-Option "  rc -Count 200 -PageSize 50  # Custom count and page size"

        Write-Header "NETWORK COMMANDS"
        Write-Cmd "ip" "Show IPv4 addresses (excludes 169.* addresses)"
        Write-Cmd "Clear-DNSCache" "Flush DNS cache"
        Write-Cmd "Flush-DNS" "Alias for Clear-DNSCache"

        Write-Header "SSH COMMANDS"
        Write-Cmd "Connect-SSH <server>" "Connect to SSH server using saved credentials (Alias: cssh)"
        Write-Cmd "Connect-SSHTunnel <server> [RemotePort] [LocalPort] [-RemoteHost]" "Create SSH tunnel (Aliases: tunnel, tssh)"
        Write-Option "  Ex: tunnel myserver | tunnel myserver 3306 | tunnel myserver postgres 5433"
        Write-Option "  DB shortcuts: postgres, mysql, mssql, mongodb, redis, oracle"
        Write-Option "  Supports key files (.pem) - add keyFile to server config"
        Write-Option "  Configure servers in config.json (copy from config.example.json)"

        Write-Header "AI INTEGRATION COMMANDS"
        Write-Cmd "ai-rules <type> [-RuleType <type>]" "Generate AI rules files (Generic/Cursor/Claude)"
        Write-Option "  ai-rules php               # Generate .airules (default)"
        Write-Option "  ai-rules laravel -RuleType Cursor  # Generate .cursorrules"
        Write-Option "  ai-rules react -RuleType Claude    # Generate .clauderules"
        Write-Option "  ai-rules -Auto             # Auto-detect project type"
        Write-Cmd "context" "Generate project summary for AI tools"
        Write-Option "  context                    # Full project context"
        Write-Option "  context -Brief             # Short summary"
        Write-Option "  context -AsJson            # JSON for MCP tools"
        Write-Option "  context -Copy              # Copy to clipboard"

        Write-Header "DEVELOPMENT COMMANDS"
        Write-Cmd "port <number>" "Find what's using a port"
        Write-Option "  port 3000                  # Show process on port"
        Write-Option "  port 3000 -Kill            # Kill the process"
        Write-Option "  port -List                 # Show all listening ports"
        Write-Cmd "proj" "Show project type and info"
        Write-Option "  proj                       # Current directory"
        Write-Option "  proj -AsJson               # JSON output for AI"
        Write-Cmd "serve" "Start dev server (auto-detects project type)"
        Write-Option "  serve                      # Auto-detect and start"
        Write-Option "  serve -Port 8080           # Custom port"
        Write-Option "  serve php                  # Force PHP server"
        Write-Cmd "gs" "Quick git status with branch info"
        Write-Option "  gs                         # Pretty status"
        Write-Option "  gs -AsJson                 # JSON for AI tools"
        Write-Cmd "search <pattern>" "Search in project files"
        Write-Option "  search 'function login'    # Search all files"
        Write-Option "  search 'TODO' -Type php    # Only PHP files"
        Write-Option "  search 'import' -Type js,ts# JS/TS files"
        Write-Cmd "http <method> <url>" "Quick HTTP requests"
        Write-Option "  http GET http://localhost:3000/api/health"
        Write-Option "  http POST http://localhost:3000/api -Body @{name='test'}"
        Write-Cmd "services" "Check dev services status"
        Write-Option "  services                   # Show all services"
        Write-Option "  services docker node       # Check specific ones"
        Write-Cmd "useenv" "Load .env file into session"
        Write-Option "  useenv                     # Load .env"
        Write-Option "  useenv .env.local          # Load specific file"
        Write-Option "  useenv -Show               # Show current env vars"
        Write-Cmd "tail <file>" "Tail log files with filtering"
        Write-Option "  tail .\app.log             # Watch log file"
        Write-Option "  tail .\app.log -Filter 'error'"
        Write-Cmd "clip <file>" "Copy file contents to clipboard"
        Write-Option "  clip .\config.json         # Copy contents"
        Write-Option "  clip .\config.json -Path   # Copy path"
        Write-Option "  clip -Pwd                  # Copy current directory"
        Write-Cmd "art <command>" "Laravel artisan helper"
        Write-Option "  art migrate                # Run migrations"
        Write-Option "  art make:model User -m     # Create model with migration"
        Write-Option "  art tinker                 # Interactive REPL"

        Write-Header "KEYBOARD SHORTCUTS"
        Write-Cmd "$([char]0x2191) / $([char]0x2193)" "Search history by prefix"
        Write-Cmd "Ctrl+R" "Reverse search history"
    }

    Write-Host ""
}
