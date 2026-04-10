# Complete Command Reference

> All available commands in the PowerShell Dev Toolkit

## Quick Reference

| Category | Commands |
|----------|----------|
| [File & Editor](#file--editor-commands) | `e`, `npp`, `touch`, `open`, `o.` |
| [Directory](#directory-commands) | `ll`, `la`, `mkcd`, `temp` |
| [Utilities](#utility-commands) | `which`, `grep`, `sudo`, `reload`, `rc` |
| [Network](#network-commands) | `ip`, `Clear-DNSCache` |
| [SSH](#ssh-commands) | `cssh`, `tunnel`, `tssh` |
| [AI Integration](#ai-integration-commands) | `ai-rules`, `context` |
| [Development](#development-commands) | `port`, `proj`, `serve`, `gs`, `search`, `http`, `services`, `useenv`, `tail`, `clip`, `art` |
| [Toolkit Management](#toolkit-management) | `Update-Toolkit` |

---

## File & Editor Commands

### `e` / `npp`
Edit file or folder in Notepad++

```powershell
e .\file.txt                      # Edit file
e .\file.ps1 -Line 42 -Column 1   # Edit at specific line/column
e .                               # Open current folder in Notepad++
npp .\file.txt                    # Alias for 'e'
```

### `Edit-Profile`
Open your PowerShell profile in Notepad++ for editing.

```powershell
Edit-Profile
```

### `Edit-Hosts`
Edit the Windows hosts file (requires admin elevation).

```powershell
Edit-Hosts
```

### `Use-NppForGit`
Configure Git to use Notepad++ as the default editor.

```powershell
Use-NppForGit
```

### `touch`
Create a new file or update an existing file's timestamp.

```powershell
touch .\newfile.txt               # Create file or update timestamp
```

### `open`
Open a file or folder with the default Windows application.

```powershell
open .\document.pdf               # Open with default PDF viewer
open .\project                    # Open folder in Explorer
```

### `o.`
Quick shortcut to open the current folder in Windows Explorer.

```powershell
o.                                # Opens current directory
```

---

## Directory Commands

### `ll`
Enhanced directory listing with folders displayed first in a formatted table.

```powershell
ll                                # List current directory
ll .\src                          # List specific directory
```

### `la`
List all files including hidden files.

```powershell
la                                # Show all files including hidden
```

### `mkcd`
Create a directory and immediately navigate into it.

```powershell
mkcd new-project                  # Create and enter directory
```

### `temp`
Navigate to the Windows temp directory.

```powershell
temp                              # cd to $env:TEMP
```

---

## Utility Commands

### `which`
Find the location of a command or executable.

```powershell
which node                        # Find where node.exe is located
which git                         # Find git location
```

### `grep`
Alias for `Select-String` - search for text patterns in files.

```powershell
grep "pattern" .\file.txt         # Search in single file
grep "TODO" *.ps1                 # Search in all .ps1 files
```

### `sudo`
Run a command with administrator privileges.

```powershell
sudo notepad C:\Windows\System32\drivers\etc\hosts
sudo choco install nodejs
```

### `Add-Path`
Add a directory to the system or user PATH.

```powershell
Add-Path "C:\tools\bin"           # Add to system PATH
Add-Path "C:\tools\bin" -User     # Add to user PATH only
```

### `reload`
Reload your PowerShell profile without restarting the terminal.

```powershell
reload                            # Applies profile changes
```

### `recent-commands` / `rc`
Display recent unique PowerShell commands with pagination.

```powershell
rc                                # Show first page (30 commands)
rc -Interactive                   # Interactive pagination mode
rc -Page 2                        # Show page 2
rc -Count 200 -PageSize 50        # Custom count and page size
```

---

## Network Commands

### `ip`
Show IPv4 addresses (excludes link-local 169.* addresses).

```powershell
ip                                # Display all valid IPv4 addresses
```

### `Clear-DNSCache` / `Flush-DNS`
Flush the Windows DNS cache.

```powershell
Clear-DNSCache                    # Flush DNS
Flush-DNS                         # Alias
```

---

## SSH Commands

> See [SSH Setup Guide](SSH-SETUP.md) for configuration details.

### `Connect-SSH` / `cssh`
Connect to an SSH server using saved credentials.

```powershell
cssh myserver                     # Connect using server alias
cssh server.example.com           # Connect using hostname directly
```

### `Connect-SSHTunnel` / `tunnel` / `tssh`
Create an SSH tunnel for database connections or other services.

```powershell
tunnel myserver                   # Default MySQL tunnel (3306)
tunnel myserver postgres          # PostgreSQL tunnel (5432)
tunnel myserver mysql 3307        # MySQL with custom local port
tunnel myserver 5432 5433         # Custom remote and local ports
tunnel myserver 3306 -RemoteHost db.internal  # Tunnel to internal host
```

**Database Shortcuts:**
| Shortcut | Port |
|----------|------|
| `postgres` / `postgresql` | 5432 |
| `mysql` / `mariadb` | 3306 |
| `mssql` / `sqlserver` | 1433 |
| `mongodb` / `mongo` | 27017 |
| `redis` | 6379 |
| `oracle` | 1521 |

---

## AI Integration Commands

### `ai-rules`
Generate AI rules files for various coding assistants.

```powershell
ai-rules php                      # Generate .airules (generic)
ai-rules laravel -RuleType Cursor # Generate .cursorrules
ai-rules react -RuleType Claude   # Generate .clauderules
ai-rules -Auto                    # Auto-detect project type
```

**Supported Project Types:**
- PHP, Laravel
- JavaScript, TypeScript, React, Vue, Angular, Next.js
- Python, Django, Flask
- Node.js, Express
- And more...

**Rule Types:**
| Type | Output File |
|------|-------------|
| Generic (default) | `.airules` |
| Cursor | `.cursorrules` |
| Claude | `.clauderules` |

### `context`
Generate a project summary for AI tools.

```powershell
context                           # Full project context
context -Brief                    # Short summary
context -AsJson                   # JSON output for MCP tools
context -Copy                     # Copy to clipboard
```

---

## Development Commands

### `port`
Find and manage processes using specific ports.

```powershell
port 3000                         # Show what's using port 3000
port 3000 -Kill                   # Kill the process on port 3000
port -List                        # Show all listening ports
```

### `proj`
Detect and show project type information.

```powershell
proj                              # Show project type for current dir
proj -AsJson                      # JSON output for AI tools
```

### `serve`
Auto-detect project type and start the appropriate dev server.

```powershell
serve                             # Auto-detect and start server
serve -Port 8080                  # Use custom port
serve php                         # Force PHP built-in server
serve node                        # Force Node.js server
```

**Auto-Detection:**
- `package.json` - npm/yarn start
- `composer.json` - PHP built-in server
- `manage.py` - Django runserver
- `requirements.txt` - Python HTTP server

### `gs`
Quick git status with enhanced branch information.

```powershell
gs                                # Pretty git status
gs -AsJson                        # JSON output for AI tools
```

### `search`
Search for patterns across project files.

```powershell
search "function login"           # Search all files
search "TODO" -Type php           # Only PHP files
search "import" -Type js,ts       # JavaScript and TypeScript files
```

### `http`
Quick HTTP requests from the command line.

```powershell
http GET http://localhost:3000/api/health
http POST http://localhost:3000/api -Body @{name='test'}
http PUT http://localhost:3000/api/1 -Body @{name='updated'}
http DELETE http://localhost:3000/api/1
```

### `services`
Check the status of development services.

```powershell
services                          # Show all common services
services docker node postgres     # Check specific services
```

### `useenv`
Load environment variables from a `.env` file into the current session.

```powershell
useenv                            # Load .env from current directory
useenv .env.local                 # Load specific env file
useenv -Show                      # Show current environment variables
```

### `tail`
Watch and tail log files with optional filtering.

```powershell
tail .\logs\app.log               # Watch log file
tail .\logs\app.log -Filter "error"    # Filter for errors
tail .\logs\app.log -Filter "warning"  # Filter for warnings
```

### `clip`
Copy file contents or paths to clipboard.

```powershell
clip .\config.json                # Copy file contents to clipboard
clip .\config.json -Path          # Copy file path to clipboard
clip -Pwd                         # Copy current directory path
```

### `art`
Laravel Artisan command helper.

```powershell
art migrate                       # Run migrations
art make:model User -m            # Create model with migration
art make:controller UserController
art tinker                        # Interactive REPL
art route:list                    # List all routes
art cache:clear                   # Clear application cache
```

---

## Toolkit Management

### `Update-Toolkit`
Self-update the toolkit by pulling the latest changes from git.

```powershell
Update-Toolkit                    # Pull latest, show changes, reload module
Update-Toolkit -CheckOnly         # Check for updates without applying
Update-Toolkit -Force             # Skip confirmation prompt
```

After updating, the module is re-imported automatically so new commands and aliases are available immediately.

**Automatic Update Checks:**

The toolkit checks for available updates once per day on shell startup (configurable). To change the frequency, set `toolkit.updateCheckDays` in `config.json`:

```json
{
  "toolkit": {
    "updateCheckDays": 7
  }
}
```

Set to `0` to disable automatic checks entirely.

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Up / Down | Search command history by prefix |
| `Ctrl+R` | Reverse search through history |

---

## Getting Help

```powershell
helpme                            # Show all commands
helpme -ProfileOnly               # Show only profile commands
helpme -ScriptsOnly               # Show only script commands
```

