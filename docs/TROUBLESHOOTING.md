# Troubleshooting Guide

> Solutions for common issues with the PowerShell Dev Toolkit

## Table of Contents

- [Installation Issues](#installation-issues)
- [Script Execution Issues](#script-execution-issues)
- [SSH Connection Issues](#ssh-connection-issues)
- [Command Not Found](#command-not-found)
- [Configuration Issues](#configuration-issues)
- [Development Server Issues](#development-server-issues)
- [WSL Issues](#wsl-issues)

---

## Installation Issues

### Setup Script Fails

**Problem:** `Setup-Environment.ps1` fails or doesn't complete.

**Solutions:**

1. Run PowerShell as Administrator
2. Check execution policy:
   ```powershell
   Get-ExecutionPolicy
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```
3. Run setup manually:
   ```powershell
   .\Setup-Environment.ps1 -Verbose
   ```

### Profile Not Updated

**Problem:** Commands aren't available after setup.

**Solutions:**

1. Reload your profile:
   ```powershell
   . $PROFILE
   ```

2. Check if profile exists:
   ```powershell
   Test-Path $PROFILE
   ```

3. Manually update profile:
   ```powershell
   .\Setup-Environment.ps1 -UpdateProfile
   ```

4. Verify profile contents:
   ```powershell
   notepad $PROFILE
   ```

---

## Script Execution Issues

### "Running Scripts is Disabled"

**Problem:** `File cannot be loaded because running scripts is disabled on this system`

**Solution:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "Script Not Digitally Signed"

**Problem:** Script blocked due to signature requirements.

**Solution:**
```powershell
# Option 1: Allow local scripts
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Option 2: Bypass for current session only
powershell -ExecutionPolicy Bypass -File .\script.ps1
```

### Permission Denied

**Problem:** Access denied when running scripts.

**Solutions:**

1. Run as Administrator:
   ```powershell
   sudo .\script.ps1
   ```

2. Check file permissions:
   ```powershell
   Get-Acl .\script.ps1 | Format-List
   ```

---

## SSH Connection Issues

### "Credential File Not Found"

**Problem:** `Credential file not found!`

**Solution:**
```powershell
# Create creds directory
New-Item -Path ".\creds" -ItemType Directory -Force

# Store credentials
$cred = Get-Credential -UserName 'your-ssh-username'
$cred | Export-Clixml '.\creds\ssh-credentials.xml'
```

### "Neither WSL nor Posh-SSH Available"

**Problem:** No SSH method available.

**Solutions:**

1. **Install WSL (Recommended):**
   ```powershell
   wsl --install
   # Restart computer after installation
   ```

2. **Install Posh-SSH:**
   ```powershell
   Install-Module -Name Posh-SSH -Scope CurrentUser -Force
   ```

### Connection Timeout

**Problem:** SSH connection times out.

**Solutions:**

1. Check server hostname in `config.json`
2. Verify network connectivity:
   ```powershell
   Test-NetConnection -ComputerName server.example.com -Port 22
   ```
3. Check firewall settings
4. Verify VPN connection if required

### Authentication Failed

**Problem:** SSH authentication fails.

**Solutions:**

1. Verify username is correct
2. Re-create credential file:
   ```powershell
   $cred = Get-Credential -UserName 'correct-username'
   $cred | Export-Clixml '.\creds\ssh-credentials.xml'
   ```
3. Test password manually:
   ```powershell
   wsl ssh your-username@server.example.com
   ```

### sshpass Installation Fails

**Problem:** Cannot install sshpass in WSL.

**Solutions:**

1. Update WSL packages first:
   ```powershell
   wsl bash -c "sudo apt-get update"
   wsl bash -c "sudo apt-get install -y sshpass"
   ```

2. If apt fails, check WSL distribution:
   ```powershell
   wsl --list --verbose
   ```

### Tunnel Connection Refused

**Problem:** `Connection refused` when using tunnel.

**Solutions:**

1. Check if the remote service is running
2. Verify the remote port is correct
3. Check if the local port is already in use:
   ```powershell
   port <local-port>
   ```
4. Try a different local port:
   ```powershell
   tunnel myserver postgres 5433
   ```

---

## Command Not Found

### "Command Not Recognized"

**Problem:** Commands like `cssh`, `serve`, `gs` not recognized.

**Solutions:**

1. Reload profile:
   ```powershell
   . $PROFILE
   ```

2. Re-run setup:
   ```powershell
   .\Setup-Environment.ps1 -UpdateProfile
   ```

3. Check if scripts exist:
   ```powershell
   Test-Path "$PSScriptRoot\Connect-SSH.ps1"
   ```

4. Manually add to profile:
   ```powershell
   notepad $PROFILE
   # Add: Set-Alias cssh "C:\path\to\Connect-SSH.ps1"
   ```

### Alias Conflicts

**Problem:** Alias conflicts with existing commands.

**Solution:**
Check for conflicts:
```powershell
Get-Alias <alias-name>
Get-Command <command-name>
```

Remove conflicting alias:
```powershell
Remove-Alias <alias-name>
```

---

## Configuration Issues

### "config.json Not Found"

**Problem:** Scripts fail because config.json doesn't exist.

**Solution:**
```powershell
Copy-Item config.example.json config.json
notepad config.json
```

### Invalid JSON in Config

**Problem:** `ConvertFrom-Json` error when loading config.

**Solutions:**

1. Validate JSON syntax:
   ```powershell
   Get-Content config.json | ConvertFrom-Json
   ```

2. Common JSON issues:
   - Missing commas between properties
   - Trailing commas (not allowed in JSON)
   - Unescaped backslashes (use `\\` in paths)

3. Reset to example:
   ```powershell
   Copy-Item config.example.json config.json
   ```

### Paths With Spaces

**Problem:** Paths with spaces cause errors.

**Solution:**
Always quote paths in `config.json`:
```json
{
  "editor": {
    "notepadPlusPlus": "C:\\Program Files\\Notepad++\\notepad++.exe"
  }
}
```

---

## Development Server Issues

### Port Already in Use

**Problem:** `serve` fails because port is in use.

**Solutions:**

1. Find what's using the port:
   ```powershell
   port 3000
   ```

2. Kill the process:
   ```powershell
   port 3000 -Kill
   ```

3. Use a different port:
   ```powershell
   serve -Port 8080
   ```

### Project Type Not Detected

**Problem:** `serve` doesn't detect project type.

**Solutions:**

1. Check for project files:
   ```powershell
   Test-Path package.json
   Test-Path composer.json
   ```

2. Force server type:
   ```powershell
   serve php
   serve node
   serve python
   ```

3. Check project info:
   ```powershell
   proj
   ```

### Node/npm Not Found

**Problem:** `serve` fails for Node projects.

**Solution:**
```powershell
# Check if Node is installed
node --version
npm --version

# If not, install from https://nodejs.org/
# Then reload terminal
```

### PHP Not Found

**Problem:** PHP server fails to start.

**Solution:**
```powershell
# Check PHP installation
php --version

# If not in PATH, add it or use full path in config
```

---

## WSL Issues

### WSL Not Installed

**Problem:** WSL commands fail.

**Solution:**
```powershell
# Install WSL
wsl --install

# Restart computer
# Then set up default distribution
wsl --set-default Ubuntu
```

### WSL Distribution Not Set

**Problem:** `The Windows Subsystem for Linux has no installed distributions`

**Solution:**
```powershell
# List available distributions
wsl --list --online

# Install Ubuntu (recommended)
wsl --install -d Ubuntu

# Set as default
wsl --set-default Ubuntu
```

### WSL Network Issues

**Problem:** WSL can't access network resources.

**Solutions:**

1. Restart WSL:
   ```powershell
   wsl --shutdown
   wsl
   ```

2. Check DNS in WSL:
   ```bash
   wsl cat /etc/resolv.conf
   ```

3. Reset WSL networking:
   ```powershell
   wsl --shutdown
   netsh winsock reset
   # Restart computer
   ```

---

## General Tips

### Debug Mode

Run scripts with verbose output:
```powershell
$VerbosePreference = "Continue"
.\Script.ps1
```

### Check Dependencies

```powershell
# PowerShell version
$PSVersionTable.PSVersion

# Git
git --version

# WSL
wsl --version

# Node
node --version

# PHP
php --version
```

### Reset Everything

If all else fails:

```powershell
# 1. Remove profile additions
notepad $PROFILE
# Remove toolkit-related lines

# 2. Re-run setup
.\Setup-Environment.ps1

# 3. Reload profile
. $PROFILE

# 4. Test
helpme
```

---

## Getting Help

If you're still stuck:

1. Check [GitHub Issues](https://github.com/joshuaevan/powershell-dev-toolkit/issues)
2. Open a new issue with:
   - PowerShell version (`$PSVersionTable.PSVersion`)
   - Windows version (`[System.Environment]::OSVersion`)
   - Error message (full text)
   - Steps to reproduce

---

## See Also

- [SSH Setup Guide](SSH-SETUP.md)
- [Commands Reference](COMMANDS.md)
- [Contributing Guidelines](../CONTRIBUTING.md)

