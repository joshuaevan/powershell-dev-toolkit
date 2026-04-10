# Contributing to PowerShell Dev Toolkit

First off, thank you for considering contributing to PowerShell Dev Toolkit! 🎉

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples**
- **Describe the behavior you observed and what you expected**
- **Include PowerShell version** (`$PSVersionTable.PSVersion`)
- **Include Windows version**
- **Include relevant logs or error messages**

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Use a clear and descriptive title**
- **Provide a step-by-step description of the suggested enhancement**
- **Provide specific examples to demonstrate the steps**
- **Describe the current behavior and explain which behavior you expected to see**
- **Explain why this enhancement would be useful**

### Pull Requests

1. **Fork the repository**
2. **Create a new branch** from `main`:
  ```powershell
   git checkout -b feature/your-feature-name
  ```
3. **Make your changes**:
  - Follow the existing code style
  - Add comments for complex logic
  - Update documentation if needed
4. **Test your changes**:
  - Test on a clean Windows machine if possible
  - Ensure backward compatibility
5. **Commit your changes**:
  ```powershell
   git commit -m "Add feature: your feature description"
  ```
6. **Push to your fork**:
  ```powershell
   git push origin feature/your-feature-name
  ```
7. **Open a Pull Request** with a clear title and description

## Coding Standards

### PowerShell Script Guidelines

1. **Use meaningful variable names**
  ```powershell
   # Good
   $serverHostname = "example.com"

   # Bad
   $s = "example.com"
  ```
2. **Include comment-based help** for all scripts
  ```powershell
   <#
   .SYNOPSIS
       Brief description

   .DESCRIPTION
       Detailed description

   .PARAMETER Name
       Parameter description

   .EXAMPLE
       script.ps1 -Name "test"
   #>
  ```
3. **Use approved verbs** for function names
  - Get-, Set-, New-, Remove-, Add-, etc.
  - Check: `Get-Verb`
4. **Handle errors gracefully**
  ```powershell
   try {
       # Your code
   } catch {
       Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
       exit 1
   }
  ```
5. **Support common parameters** when appropriate
  ```powershell
   [CmdletBinding()]
   param(
       [Parameter(Mandatory=$true)]
       [string]$Name
   )
  ```
6. **Provide meaningful output**
  - Use colored output for better UX
  - Support `-AsJson` for programmatic use where appropriate
  - Show progress for long-running operations

### Configuration

- **Never hardcode user-specific information**
- **Use `config.json` for user settings**
- **Provide sensible defaults**
- **Document all configuration options** in `config.example.json`

### Security

- **Never commit credentials** or sensitive data
- **Use encrypted credential storage** (Export-Clixml)
- **Always validate user input**
- **Use secure connections** (SSH, HTTPS)

## Documentation

- Update `README.md` if you add new features
- Add examples to help text
- Document configuration options
- Update `helpme.ps1` for new commands

## Testing

Tests are written with [Pester 5](https://pester.dev/) in the `tests/` directory. Run the full suite with:

```powershell
.\Invoke-Tests.ps1
```

This installs Pester 5+ if needed and runs all tests with detailed output. Tests also run automatically via GitHub Actions CI on every push and pull request.

When adding new commands, please add corresponding test coverage. Tests should use the Pester 5 `BeforeAll` pattern:

```powershell
BeforeAll {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    Import-Module (Join-Path $repoRoot "PowerShellDevToolkit") -Force
}

Describe "Your-Command" {
    It "Should do something" {
        # test code
    }
}
```

Also test manually:

1. **Test your changes** on Windows 10 and 11
2. **Test with PowerShell 5.1 and 7+**
3. **Test without WSL** (fallback scenarios)
4. **Test with missing dependencies** (graceful degradation)

## Project Structure

```
powershell-dev-toolkit/
├── PowerShellDevToolkit/           # The PS module
│   ├── PowerShellDevToolkit.psd1   # Module manifest (version, exports)
│   ├── PowerShellDevToolkit.psm1   # Root module (auto-loader, aliases)
│   ├── Public/                     # Exported functions (one per file)
│   │   ├── Connect-SSH.ps1
│   │   ├── Get-GitQuick.ps1
│   │   └── ...
│   └── Private/                    # Internal helpers (not exported)
│       └── Get-ScriptConfig.ps1
├── tests/                          # Pester tests
├── docs/                           # Documentation
├── config.example.json             # Configuration template
├── Setup-Environment.ps1           # Bootstrap / installer
├── README.md
├── LICENSE
└── creds/                          # Credentials (gitignored)
```

### Adding a new command

1. Create `PowerShellDevToolkit\Public\Verb-Noun.ps1` with a `function Verb-Noun { ... }` wrapper
2. Add the function name to `FunctionsToExport` in `PowerShellDevToolkit.psd1`
3. Optionally add a short alias in `PowerShellDevToolkit.psm1` and `AliasesToExport` in the `.psd1`
4. Add a test file `tests\Verb-Noun.Tests.ps1`
5. Update `Show-Help` in `Public\Show-Help.ps1` with the new command reference

## Commit Messages

Use clear and meaningful commit messages:

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting)
- **refactor**: Code refactoring
- **test**: Adding tests
- **chore**: Maintenance tasks

Examples:

```
feat: add support for SQLServer tunneling
fix: resolve credential loading on PowerShell 7
docs: update SSH setup instructions
refactor: simplify server configuration logic
```

## Questions?

Feel free to open an issue with the `question` label if you need clarification on anything.

## Code of Conduct

Be respectful and constructive. We're all here to learn and help each other.

---

Thank you for contributing! 🚀