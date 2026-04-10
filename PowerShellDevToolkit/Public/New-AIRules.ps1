function New-AIRules {
    <#
    .SYNOPSIS
        Generate AI rules file for AI assistance with language-specific templates.

    .DESCRIPTION
        Creates an AI rules file in the current directory with language/framework
        best practices, available PowerShell shortcut commands, SSH server shortcuts,
        and project structure conventions.

    .PARAMETER Language
        The language or framework: php, laravel, react, node, perl, python, or 'auto' to detect.

    .PARAMETER RuleType
        Type of AI rules file to generate: Generic (default), Cursor, or Claude.

    .PARAMETER Append
        Append to existing rules file instead of overwriting.

    .PARAMETER Auto
        Auto-detect project type.

    .PARAMETER OutputPath
        Custom output path (overrides -RuleType default filename).

    .EXAMPLE
        New-AIRules php
        ai-rules laravel -RuleType Cursor
        ai-rules -Auto
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [ValidateSet('php', 'laravel', 'symfony', 'react', 'node', 'perl', 'python', 'auto', '')]
        [string]$Language = 'auto',

        [Parameter(Position = 1)]
        [ValidateSet('Generic', 'Cursor', 'Claude')]
        [string]$RuleType = 'Generic',

        [switch]$Append,
        [switch]$Auto,

        [string]$OutputPath
    )

    if ($Auto) { $Language = 'auto' }

    if ([string]::IsNullOrEmpty($OutputPath)) {
        $OutputPath = switch ($RuleType) {
            'Cursor'  { '.\.cursorrules' }
            'Claude'  { '.\.clauderules' }
            'Generic' { '.\.airules' }
            default   { '.\.airules' }
        }
    }

    function Get-DetectedLanguage {
        param([string]$Path = '.')

        if ((Test-Path "$Path\artisan") -and (Test-Path "$Path\composer.json")) {
            $composer = Get-Content "$Path\composer.json" -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($composer.require.'laravel/framework' -or $composer.require.'illuminate/support') {
                return 'laravel'
            }
        }

        if (Test-Path "$Path\symfony.lock") { return 'symfony' }
        if ((Test-Path "$Path\composer.json") -and (Test-Path "$Path\config\bundles.php")) { return 'symfony' }

        if (Test-Path "$Path\package.json") {
            $pkg = Get-Content "$Path\package.json" -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($pkg.dependencies.react -or $pkg.devDependencies.react) {
                return 'react'
            }
            return 'node'
        }

        if ((Test-Path "$Path\composer.json") -or (Get-ChildItem "$Path\*.php" -ErrorAction SilentlyContinue)) {
            return 'php'
        }

        if ((Test-Path "$Path\Makefile.PL") -or (Test-Path "$Path\cpanfile") -or (Get-ChildItem "$Path\*.pl" -ErrorAction SilentlyContinue) -or (Get-ChildItem "$Path\*.pm" -ErrorAction SilentlyContinue)) {
            return 'perl'
        }

        if ((Test-Path "$Path\requirements.txt") -or (Test-Path "$Path\pyproject.toml") -or (Test-Path "$Path\setup.py")) {
            return 'python'
        }

        return $null
    }

    $ruleTypeTitle = switch ($RuleType) {
        'Cursor'  { 'Cursor AI Rules' }
        'Claude'  { 'Claude AI Rules' }
        'Generic' { 'AI Assistant Rules' }
        default   { 'AI Assistant Rules' }
    }

    $commonHeader = @"
# $ruleTypeTitle

## Environment
- OS: Windows 10/11
- Terminal: PowerShell (primary), WSL available for Linux commands
- Editor: Cursor IDE with Notepad++ for quick edits

## Available PowerShell Commands

### File & Editor
- ``e <path>`` or ``npp`` - Edit file in Notepad++ (e.g., ``e .\config.php -Line 42``)
- ``touch <path>`` - Create file or update timestamp
- ``open <path>`` - Open with default application
- ``o.`` - Open current folder in Explorer

### Directory Navigation
- ``ll`` - Enhanced directory listing (folders first)
- ``la`` - List all including hidden files
- ``mkcd <path>`` - Create directory and cd into it
- ``temp`` - Navigate to temp directory

### Utilities
- ``which <cmd>`` - Find command location
- ``grep`` - Alias for Select-String
- ``sudo <cmd>`` - Run as administrator
- ``reload`` - Reload PowerShell profile
- ``rc`` or ``recent-commands`` - Show recent command history

### Network
- ``ip`` - Show IPv4 addresses
- ``Flush-DNS`` - Clear DNS cache

### SSH & Database Tunnels
- ``cssh <server>`` - SSH to server (e.g., ``cssh myserver``)
- ``tunnel <server> <port>`` - Create SSH tunnel for database
  - ``tunnel myserver mysql`` - MySQL tunnel (port 3306)
  - ``tunnel myserver postgres`` - PostgreSQL tunnel (port 5432)
  - ``tunnel myserver 3306 3307`` - Custom local port
- Server shortcuts configured in config.json

### Development
- ``port <number>`` - Find/kill process on port (e.g., ``port 3000 -Kill``)
- ``serve`` - Start dev server (auto-detects project type)
- ``proj`` - Show project info and type
- ``gs`` - Quick git status
- ``useenv`` - Load .env file into session
- ``context`` - Generate project context for AI
- ``search <pattern>`` - Search in project files

"@

    $templates = @{
        'php' = "$commonHeader`n## Language: PHP`n`n### Code Style`n- Follow PSR-12 coding standards`n- Use strict types: ``declare(strict_types=1);```n- Prefer typed properties and return types (PHP 7.4+)`n- Use meaningful variable names`n- Document complex logic with PHPDoc blocks`n`n### Best Practices`n- Validate all user input`n- Use prepared statements for database queries`n- Escape output appropriately`n- Handle errors with try/catch`n- Use Composer for dependency management`n`n### Testing`n- Use PHPUnit for unit tests`n- Run tests: ``vendor/bin/phpunit``"
        'laravel' = "$commonHeader`n## Framework: Laravel`n`n### Artisan Commands (use ``art`` alias)`n- ``art migrate`` - Run migrations`n- ``art make:model ModelName -m`` - Create model with migration`n- ``art tinker`` - Interactive REPL`n- ``art serve`` - Start development server`n- ``art route:list`` - Show all routes`n- ``art cache:clear`` - Clear application cache`n`n### Best Practices`n- Never commit .env file`n- Use migrations for all database changes`n- Use Form Requests for validation`n- Queue long-running tasks`n`n### Debugging`n- Check ``storage/logs/laravel.log`` for errors`n- Use ``dd()`` or ``dump()`` for debugging"
        'symfony' = "$commonHeader`n## Framework: Symfony`n`n### Console Commands`n- ``php bin/console`` - Symfony console`n- ``php bin/console make:controller`` - Generate controller`n- ``php bin/console doctrine:migrations:migrate`` - Run migrations`n- ``php bin/console cache:clear`` - Clear cache`n`n### Best Practices`n- Use .env.local for local overrides`n- Use Doctrine migrations for schema changes`n- Prefer constructor injection"
        'react' = "$commonHeader`n## Framework: React (with Node.js)`n`n### Package Manager Commands`n- ``npm install`` - Install dependencies`n- ``npm start`` or ``npm run dev`` - Start dev server`n- ``npm run build`` - Production build`n- ``npm test`` - Run tests`n`n### Code Style`n- Use functional components with hooks`n- Prefer TypeScript for new projects`n- Keep components small and focused`n`n### Best Practices`n- useState for local, Context/Redux for global state`n- Side effects in useEffect with proper cleanup`n- Use React.lazy for code splitting"
        'node' = "$commonHeader`n## Runtime: Node.js`n`n### Package Manager Commands`n- ``npm install`` - Install dependencies`n- ``npm start`` - Start application`n- ``npm run dev`` - Development mode`n- ``npm test`` - Run tests`n`n### Code Style`n- Use ES modules or CommonJS consistently`n- Prefer async/await over callbacks`n- Handle errors properly`n- Use environment variables for configuration`n`n### Best Practices`n- Never commit node_modules or .env`n- Validate input data`n- Use proper error handling middleware"
        'perl' = "$commonHeader`n## Language: Perl`n`n### Running Perl`n- ``perl script.pl`` - Run a script`n- ``perl -c script.pl`` - Syntax check`n- ``perl -w script.pl`` - Enable warnings`n`n### Code Style`n- Always use ``use strict;`` and ``use warnings;```n- Prefer lexical variables (my)`n- Document with POD`n`n### Testing`n- Use Test::More for tests`n- Run tests: ``prove -l t/``"
        'python' = "$commonHeader`n## Language: Python`n`n### Running Python`n- ``python script.py`` - Run a script`n- ``pip install -r requirements.txt`` - Install dependencies`n`n### Code Style`n- Follow PEP 8 style guide`n- Use type hints (Python 3.5+)`n- Prefer f-strings for formatting`n`n### Testing`n- pytest: ``pytest```n- unittest: ``python -m unittest discover``"
    }

    if ($Language -eq 'auto' -or [string]::IsNullOrEmpty($Language)) {
        $detected = Get-DetectedLanguage
        if ($detected) {
            $Language = $detected
            Write-Host "Detected project type: " -NoNewline -ForegroundColor Cyan
            Write-Host $Language -ForegroundColor Green
        } else {
            Write-Host "Could not auto-detect project type. Please specify: php, laravel, react, node, perl, python" -ForegroundColor Yellow
            return
        }
    }

    if (-not $templates.ContainsKey($Language)) {
        Write-Host "Unknown language: $Language" -ForegroundColor Red
        Write-Host "Supported: php, laravel, symfony, react, node, perl, python" -ForegroundColor Yellow
        return
    }

    $content = $templates[$Language]

    if ($Append -and (Test-Path $OutputPath)) {
        $existing = Get-Content $OutputPath -Raw
        $content = $existing + "`n`n" + "# Additional Rules`n" + $content
    }

    $content | Set-Content $OutputPath -Encoding UTF8

    Write-Host ""
    Write-Host "Created " -NoNewline -ForegroundColor Green
    Write-Host $OutputPath -NoNewline -ForegroundColor Yellow
    Write-Host " (" -NoNewline -ForegroundColor Green
    Write-Host $RuleType -NoNewline -ForegroundColor Cyan
    Write-Host " format) with " -NoNewline -ForegroundColor Green
    Write-Host $Language -NoNewline -ForegroundColor Magenta
    Write-Host " rules" -ForegroundColor Green
    Write-Host ""
    Write-Host "The file includes:" -ForegroundColor Cyan
    Write-Host "  - Your PowerShell shortcut commands" -ForegroundColor White
    Write-Host "  - SSH server shortcuts and database tunnels" -ForegroundColor White
    Write-Host "  - $Language best practices and conventions" -ForegroundColor White
    Write-Host ""
}
