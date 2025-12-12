# PowerShell Dev Toolkit for Windows

> A comprehensive collection of PowerShell productivity scripts for Windows developers. Streamline your development workflow with SSH tunneling, project management, AI integration, and much more.

[![Windows](https://img.shields.io/badge/Platform-Windows%2010%2F11-blue?logo=windows)](https://www.microsoft.com/windows)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?logo=powershell)](https://docs.microsoft.com/powershell/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## ✨ Features

- **🔐 SSH Management** - Easy SSH connections and database tunneling with credential management
- **🛠️ Development Tools** - Auto-detecting dev servers, port management, project detection
- **🔍 Code Search** - Fast project-wide search with smart filtering
- **📊 Git Integration** - Enhanced git status and branch information
- **🤖 AI Assistant Integration** - Generate AI rules files for Cursor IDE, Claude, and other AI coding assistants
- **📝 Log Monitoring** - Real-time log file watching with filtering
- **🚀 Quick Commands** - 30+ productivity commands with short aliases

## 🚀 Quick Start

### Installation

1. **Clone the repository**
   ```powershell
   git clone https://github.com/joshuaevan/powershell-dev-toolkit.git
   cd powershell-dev-toolkit
   ```

2. **Run the setup script**
   ```powershell
   .\Setup-Environment.ps1
   ```
   
   The setup will:
   - Check all dependencies
   - Guide you through configuration
   - Update your PowerShell profile with aliases
   - Install missing PowerShell modules (optional)

3. **Configure your settings**
   ```powershell
   # Copy the example config
   Copy-Item config.example.json config.json
   
   # Edit with your settings (servers, paths, etc.)
   notepad config.json
   ```

4. **Reload your profile**
   ```powershell
   . $PROFILE
   # or just type: reload
   ```

5. **Test it out**
   ```powershell
   helpme  # Show all commands
   ```

## 📋 Requirements

### Essential
- **Windows 10/11**
- **PowerShell 5.1+** (comes with Windows)
- **Git** - [Download](https://git-scm.com/download/win)

### Recommended
- **WSL (Windows Subsystem for Linux)** - For better SSH support
  ```powershell
  wsl --install
  ```
- **Notepad++** - For quick file editing - [Download](https://notepad-plus-plus.org/)

### Optional (Install as needed)
- **Node.js & npm** - For JavaScript/Node projects - [Download](https://nodejs.org/)
- **PHP** - For PHP/Laravel projects - [Download](https://windows.php.net/download/)
- **Python** - For Python projects - [Download](https://www.python.org/downloads/)
- **Composer** - For PHP dependency management - [Download](https://getcomposer.org/)

## 🎯 Key Commands

### SSH & Remote Access
```powershell
cssh myserver                    # SSH to server
tunnel myserver postgres         # PostgreSQL tunnel (port 5432)
tunnel myserver mysql 3307       # MySQL tunnel with custom local port
```

### Development
```powershell
serve                            # Auto-detect & start dev server
serve -Port 8080                 # Custom port
port 3000                        # Check what's using port 3000
port 3000 -Kill                  # Kill process on port
search "function login"          # Search codebase
gs                               # Pretty git status
```

### Project Management
```powershell
context                          # Generate project summary
context -Copy                    # Copy to clipboard
proj                             # Detect project type
useenv                           # Load .env file
```

### AI Integration
```powershell
ai-rules php                     # Generate .airules for PHP (default)
ai-rules laravel -RuleType Cursor   # Generate .cursorrules for Laravel
ai-rules react -RuleType Claude     # Generate .clauderules for React
ai-rules -Auto                   # Auto-detect project type
```

### Utilities
```powershell
tail .\app.log                   # Watch log file
tail .\app.log -Filter "error"   # Filter for errors
rc                               # Browse command history
rc -Interactive                  # Interactive history browser
```

## 📖 Full Command Reference

Run `helpme` to see all commands, or check the [complete documentation](docs/COMMANDS.md).

## ⚙️ Configuration

### SSH Setup

1. **Configure servers in `config.json`:**
   ```json
   {
     "ssh": {
       "credentialFile": "ssh-credentials.xml",
       "servers": {
         "myserver": {
           "hostname": "server.example.com",
           "description": "Production server"
         }
       }
     }
   }
   ```

2. **Store SSH credentials:**
   ```powershell
   # Create creds directory
   New-Item -Path ".\creds" -ItemType Directory -Force
   
   # Store encrypted credentials
   $cred = Get-Credential -UserName 'your-ssh-username'
   $cred | Export-Clixml '.\creds\ssh-credentials.xml'
   ```

### Editor Integration

Configure your preferred editor in `config.json`:
```json
{
  "editor": {
    "notepadPlusPlus": "C:\\Program Files\\Notepad++\\notepad++.exe"
  }
}
```

## 🔧 Customization

### Adding Custom Commands

1. Create a new `.ps1` file in the scripts directory
2. Add an alias in your PowerShell profile
3. Run `reload` to apply changes

### Extending SSH Servers

Edit `config.json` to add more servers:
```json
"servers": {
  "prod": {
    "hostname": "prod.example.com",
    "description": "Production"
  },
  "staging": {
    "hostname": "staging.example.com", 
    "description": "Staging"
  }
}
```

## 📚 Documentation

- [Complete Command Reference](docs/COMMANDS.md)
- [SSH Configuration Guide](docs/SSH-SETUP.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Contributing Guidelines](CONTRIBUTING.md)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 🐛 Troubleshooting

### Scripts won't execute
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### SSH commands not working
1. Check if WSL is installed: `wsl --version`
2. If not, install Posh-SSH: `Install-Module -Name Posh-SSH`
3. Verify credentials file exists: `Test-Path .\creds\ssh-credentials.xml`

### Missing commands after setup
```powershell
# Reload your profile
. $PROFILE

# Or rerun setup
.\Setup-Environment.ps1 -UpdateProfile
```

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built for developers who love PowerShell
- Inspired by Unix productivity tools
- Optimized for Windows 10/11 development environments

## 📧 Support

- **Issues**: [GitHub Issues](https://github.com/joshuaevan/powershell-dev-toolkit/issues)
- **Discussions**: [GitHub Discussions](https://github.com/joshuaevan/powershell-dev-toolkit/discussions)

---

**Made with ❤️ for Windows developers**

*Star ⭐ this repo if you find it helpful!*
