# SSH Configuration Guide

> Complete guide to setting up SSH connections and tunnels

## Prerequisites

You need **one** of the following:

1. **WSL (Windows Subsystem for Linux)** - Recommended
   ```powershell
   wsl --install
   ```

2. **Posh-SSH Module** - Alternative if WSL unavailable
   ```powershell
   Install-Module -Name Posh-SSH -Scope CurrentUser
   ```

## Quick Setup

### 1. Create Configuration File

Copy the example config and edit it:

```powershell
Copy-Item config.example.json config.json
notepad config.json
```

### 2. Configure Your Servers

Edit `config.json` with your server details:

```json
{
  "ssh": {
    "credentialFile": "ssh-credentials.xml",
    "servers": {
      "prod": {
        "hostname": "production.example.com",
        "description": "Production server"
      },
      "staging": {
        "hostname": "staging.example.com",
        "description": "Staging server"
      },
      "db": {
        "hostname": "database.example.com",
        "description": "Database server"
      }
    },
    "databasePorts": {
      "postgres": 5432,
      "mysql": 3306,
      "mssql": 1433,
      "mongodb": 27017,
      "redis": 6379,
      "oracle": 1521
    }
  }
}
```

### 3. Store SSH Credentials

Create encrypted credentials (Windows DPAPI - only works on your machine):

```powershell
# Create creds directory
New-Item -Path ".\creds" -ItemType Directory -Force

# Store your credentials
$cred = Get-Credential -UserName 'your-ssh-username'
$cred | Export-Clixml '.\creds\ssh-credentials.xml'
```

> **Security Note:** The credential file is encrypted using Windows DPAPI and can only be decrypted by your Windows user account on this machine.

### 4. Test Your Connection

```powershell
cssh prod                         # Connect to 'prod' server
```

---

## Configuration Reference

### Server Configuration

Each server entry in `config.json`:

```json
"servers": {
  "alias": {
    "hostname": "server.example.com",
    "description": "Optional description"
  }
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `alias` | Yes | Short name for the server (used in commands) |
| `hostname` | Yes | Full hostname or IP address |
| `description` | No | Human-readable description |

### Database Port Shortcuts

Customize database port shortcuts:

```json
"databasePorts": {
  "postgres": 5432,
  "postgresql": 5432,
  "mysql": 3306,
  "mariadb": 3306,
  "mssql": 1433,
  "sqlserver": 1433,
  "mongodb": 27017,
  "mongo": 27017,
  "redis": 6379,
  "oracle": 1521,
  "custom-db": 9999
}
```

### Credential File

Specify a custom credential file name:

```json
"ssh": {
  "credentialFile": "my-credentials.xml",
  ...
}
```

The file is always stored in the `creds` subdirectory.

---

## Usage Examples

### Basic SSH Connection

```powershell
# Using server alias
cssh prod

# Using direct hostname
cssh server.example.com
```

### SSH Tunnels

**Database Tunnels:**

```powershell
# PostgreSQL (default port 5432)
tunnel prod postgres

# MySQL (default port 3306)
tunnel prod mysql

# MongoDB (default port 27017)
tunnel prod mongodb
```

**Custom Ports:**

```powershell
# Remote port 5432, local port 5433
tunnel prod postgres 5433

# Explicit port numbers
tunnel prod 5432 5433
```

**Tunnel to Internal Host:**

```powershell
# Connect to internal database via jump host
tunnel prod 5432 5432 -RemoteHost db.internal.example.com
```

**Tunnel Workflow:**

```
+-------------+        +-------------+        +-------------+
|  Your PC    |  SSH   |   Server    |  TCP   |  Database   |
| localhost:  |------->|   (prod)    |------->|  Internal   |
|    5432     |        |             |        |    :5432    |
+-------------+        +-------------+        +-------------+
```

---

## Multiple Credential Files

For different servers with different credentials:

### 1. Create Multiple Credential Files

```powershell
# Production credentials
$prodCred = Get-Credential -UserName 'prod-user'
$prodCred | Export-Clixml '.\creds\prod-credentials.xml'

# Development credentials
$devCred = Get-Credential -UserName 'dev-user'
$devCred | Export-Clixml '.\creds\dev-credentials.xml'
```

### 2. Switch Between Credentials

Update `config.json` when switching:

```json
"ssh": {
  "credentialFile": "prod-credentials.xml",
  ...
}
```

---

## WSL Setup (Recommended)

WSL provides better SSH compatibility and terminal handling.

### Install WSL

```powershell
wsl --install
```

### First Connection Setup

On first SSH connection, the toolkit will automatically install `sshpass` in WSL:

```
Installing sshpass in WSL (one-time setup)...
```

This enables password-based SSH authentication.

### Manual WSL Setup

If needed, manually install sshpass:

```bash
wsl bash -c "sudo apt-get update && sudo apt-get install -y sshpass"
```

---

## SSH Keys (Alternative)

For key-based authentication instead of passwords:

### 1. Generate SSH Key

```powershell
wsl bash -c "ssh-keygen -t ed25519 -C 'your_email@example.com'"
```

### 2. Copy Key to Server

```powershell
wsl bash -c "ssh-copy-id username@server.example.com"
```

### 3. Connect Without Password

After setting up keys, you can connect directly:

```powershell
wsl ssh username@server.example.com
```

> **Note:** The toolkit's credential-based commands still work alongside key-based auth.

---

## Security Best Practices

1. **Never commit `config.json` or credential files**
   - Add to `.gitignore`:
     ```
     config.json
     creds/
     ```

2. **Use strong, unique passwords** for SSH

3. **Consider SSH keys** for production servers

4. **Limit server access** - only configure servers you need

5. **Rotate credentials** periodically

---

## Connection Methods

The toolkit uses different methods based on availability:

| Priority | Method | Requirements |
|----------|--------|--------------|
| 1 | WSL + sshpass | WSL installed |
| 2 | Posh-SSH | Posh-SSH module installed |

### Check Available Methods

```powershell
# Check WSL
wsl --version

# Check Posh-SSH
Get-Module -ListAvailable Posh-SSH
```

---

## See Also

- [Troubleshooting](TROUBLESHOOTING.md) - Common SSH issues
- [Commands Reference](COMMANDS.md) - All SSH commands

