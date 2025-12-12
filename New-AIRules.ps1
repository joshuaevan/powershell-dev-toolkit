<#
.SYNOPSIS
    Generate AI rules file for AI assistance with language-specific templates.

.DESCRIPTION
    Creates an AI rules file in the current directory with:
    - Language/framework best practices
    - Available PowerShell shortcut commands
    - SSH server shortcuts and database tunnels
    - Project structure conventions

.PARAMETER Language
    The language or framework: php, laravel, react, node, perl, python, or 'auto' to detect.

.PARAMETER RuleType
    Type of AI rules file to generate: Generic (default), Cursor, or Claude.
    - Generic: Creates .airules file
    - Cursor: Creates .cursorrules file
    - Claude: Creates .clauderules file

.PARAMETER Append
    Append to existing rules file instead of overwriting.

.PARAMETER OutputPath
    Custom output path (overrides -RuleType default filename).

.EXAMPLE
    ai-rules php
    ai-rules laravel -RuleType Cursor
    ai-rules react -RuleType Claude
    ai-rules -Auto
    ai-rules php -Append
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

# If -Auto switch is used, set Language to auto
if ($Auto) { $Language = 'auto' }

# Set default output path based on RuleType if not specified
if ([string]::IsNullOrEmpty($OutputPath)) {
    $OutputPath = switch ($RuleType) {
        'Cursor'  { '.\.cursorrules' }
        'Claude'  { '.\.clauderules' }
        'Generic' { '.\.airules' }
        default   { '.\.airules' }
    }
}

# Auto-detect language from project files
function Get-DetectedLanguage {
    param([string]$Path = '.')
    
    # Check for Laravel (must check before generic PHP)
    if ((Test-Path "$Path\artisan") -and (Test-Path "$Path\composer.json")) {
        $composer = Get-Content "$Path\composer.json" -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($composer.require.'laravel/framework' -or $composer.require.'illuminate/support') {
            return 'laravel'
        }
    }
    
    # Check for Symfony
    if (Test-Path "$Path\symfony.lock") { return 'symfony' }
    if ((Test-Path "$Path\composer.json") -and (Test-Path "$Path\config\bundles.php")) { return 'symfony' }
    
    # Check for React (in package.json)
    if (Test-Path "$Path\package.json") {
        $pkg = Get-Content "$Path\package.json" -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($pkg.dependencies.react -or $pkg.devDependencies.react) {
            return 'react'
        }
        # Generic Node if no React
        return 'node'
    }
    
    # Check for PHP (generic)
    if ((Test-Path "$Path\composer.json") -or (Get-ChildItem "$Path\*.php" -ErrorAction SilentlyContinue)) {
        return 'php'
    }
    
    # Check for Perl
    if ((Test-Path "$Path\Makefile.PL") -or (Test-Path "$Path\cpanfile") -or (Get-ChildItem "$Path\*.pl" -ErrorAction SilentlyContinue) -or (Get-ChildItem "$Path\*.pm" -ErrorAction SilentlyContinue)) {
        return 'perl'
    }
    
    # Check for Python
    if ((Test-Path "$Path\requirements.txt") -or (Test-Path "$Path\pyproject.toml") -or (Test-Path "$Path\setup.py")) {
        return 'python'
    }
    
    return $null
}

# Common header for all rules
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

# Language-specific templates
$templates = @{
    'php' = @"
$commonHeader
## Language: PHP

### Code Style
- Follow PSR-12 coding standards
- Use strict types: ``declare(strict_types=1);``
- Prefer typed properties and return types (PHP 7.4+)
- Use meaningful variable names (no single letters except loops)
- Document complex logic with PHPDoc blocks

### Best Practices
- Validate all user input
- Use prepared statements for database queries (PDO or mysqli)
- Escape output appropriately (htmlspecialchars for HTML)
- Handle errors with try/catch, don't suppress with @
- Use Composer for dependency management

### Common Patterns
- Autoloading via Composer PSR-4
- Configuration in separate files or .env
- Separation of concerns (logic vs presentation)

### File Structure Convention
```
project/
├── public/          # Web root (index.php)
├── src/             # Application code
├── config/          # Configuration files
├── templates/       # View templates
├── tests/           # PHPUnit tests
├── vendor/          # Composer dependencies
└── composer.json
```

### Testing
- Use PHPUnit for unit tests
- Run tests: ``vendor/bin/phpunit``

### Debugging
- Use ``var_dump()`` or ``print_r()`` for quick debugging
- Xdebug for step debugging
- Check PHP error log location in php.ini
"@

    'laravel' = @"
$commonHeader
## Framework: Laravel

### Artisan Commands (use ``art`` alias)
- ``art migrate`` - Run migrations
- ``art make:model ModelName -m`` - Create model with migration
- ``art make:controller ControllerName`` - Create controller
- ``art tinker`` - Interactive REPL
- ``art serve`` - Start development server
- ``art route:list`` - Show all routes
- ``art cache:clear`` - Clear application cache
- ``art config:clear`` - Clear config cache

### Code Style
- Follow PSR-12 and Laravel conventions
- Use Eloquent ORM for database operations
- Prefer dependency injection over facades when testing matters
- Use Form Requests for validation
- Use Resources for API responses

### Best Practices
- Never commit .env file (use .env.example)
- Use migrations for all database changes
- Use seeders and factories for test data
- Queue long-running tasks
- Use Laravel's built-in validation
- Leverage middleware for cross-cutting concerns

### File Structure
```
app/
├── Http/
│   ├── Controllers/
│   ├── Middleware/
│   └── Requests/      # Form Request validation
├── Models/
├── Services/          # Business logic (optional)
└── Providers/
config/
database/
├── migrations/
├── seeders/
└── factories/
resources/
├── views/
├── js/
└── css/
routes/
├── web.php
└── api.php
storage/logs/          # Check laravel.log for errors
```

### Common Commands
- ``composer install`` - Install dependencies
- ``npm install && npm run dev`` - Build assets
- ``art key:generate`` - Generate app key
- ``art storage:link`` - Create storage symlink

### Testing
- ``art test`` or ``php artisan test``
- ``art make:test TestName``
- Use ``RefreshDatabase`` trait for test isolation

### Debugging
- Check ``storage/logs/laravel.log`` for errors
- Use ``dd()`` or ``dump()`` for debugging
- Laravel Telescope for request inspection (if installed)
- ``tail storage/logs/laravel.log -Filter error``
"@

    'symfony' = @"
$commonHeader
## Framework: Symfony

### Console Commands
- ``php bin/console`` - Symfony console
- ``php bin/console make:controller`` - Generate controller
- ``php bin/console make:entity`` - Generate entity
- ``php bin/console doctrine:migrations:migrate`` - Run migrations
- ``php bin/console cache:clear`` - Clear cache
- ``php bin/console debug:router`` - Show routes

### Code Style
- Follow Symfony coding standards
- Use attributes for routing and validation (Symfony 5.2+)
- Prefer constructor injection
- Use DTOs for data transfer
- Leverage Symfony's form component

### Best Practices
- Use .env.local for local overrides
- Use Doctrine migrations for schema changes
- Leverage Symfony Flex for bundle management
- Use voters for authorization
- Configure services in config/services.yaml

### File Structure
```
config/
├── packages/
├── routes/
└── services.yaml
src/
├── Controller/
├── Entity/
├── Repository/
├── Service/
└── Kernel.php
templates/             # Twig templates
public/
migrations/
var/
├── cache/
└── log/
```

### Debugging
- Check ``var/log/dev.log`` for errors
- Use Symfony Profiler (web debug toolbar)
- ``dump()`` and ``dd()`` functions available
"@

    'react' = @"
$commonHeader
## Framework: React (with Node.js)

### Package Manager Commands
- ``npm install`` or ``npm i`` - Install dependencies
- ``npm start`` or ``npm run dev`` - Start dev server
- ``npm run build`` - Production build
- ``npm test`` - Run tests

### Code Style
- Use functional components with hooks (not class components)
- Prefer TypeScript for new projects
- Use named exports for components
- Keep components small and focused
- Use meaningful component and variable names

### Best Practices
- State management: useState for local, Context/Redux for global
- Side effects in useEffect with proper cleanup
- Memoize expensive computations with useMemo
- Memoize callbacks with useCallback when passing to children
- Use React.lazy for code splitting
- Handle loading and error states

### Component Structure
```jsx
// Good component structure
import { useState, useEffect } from 'react';
import styles from './Component.module.css';

export function ComponentName({ prop1, prop2 }) {
  const [state, setState] = useState(initialValue);
  
  useEffect(() => {
    // side effect
    return () => { /* cleanup */ };
  }, [dependencies]);
  
  return (
    <div className={styles.container}>
      {/* JSX */}
    </div>
  );
}
```

### File Structure
```
src/
├── components/
│   ├── common/        # Reusable components
│   └── features/      # Feature-specific components
├── hooks/             # Custom hooks
├── context/           # React Context providers
├── services/          # API calls
├── utils/             # Helper functions
├── types/             # TypeScript types
└── App.jsx
public/
package.json
```

### Testing
- Jest + React Testing Library
- ``npm test`` - Run tests
- Test behavior, not implementation

### Debugging
- React DevTools browser extension
- Console.log in development
- Check browser DevTools Network tab for API issues
- ``port 3000`` to check if dev server port is in use
"@

    'node' = @"
$commonHeader
## Runtime: Node.js

### Package Manager Commands
- ``npm install`` - Install dependencies
- ``npm start`` - Start application
- ``npm run dev`` - Development mode (usually with nodemon)
- ``npm test`` - Run tests
- ``npm run build`` - Build (if applicable)

### Code Style
- Use ES modules (import/export) or CommonJS consistently
- Prefer async/await over callbacks
- Use meaningful variable and function names
- Handle errors properly (try/catch, .catch())
- Use environment variables for configuration

### Best Practices
- Never commit node_modules or .env
- Use .env for environment-specific config
- Validate input data
- Use proper error handling middleware (Express)
- Structure code in modules/services
- Use logging library (winston, pino) in production

### Express.js Pattern
```javascript
// Good Express pattern
import express from 'express';
const app = express();

app.use(express.json());

app.get('/api/resource', async (req, res, next) => {
  try {
    const data = await service.getData();
    res.json(data);
  } catch (error) {
    next(error);
  }
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: 'Internal server error' });
});
```

### File Structure
```
src/
├── routes/            # Route handlers
├── controllers/       # Request handlers
├── services/          # Business logic
├── models/            # Data models
├── middleware/        # Express middleware
├── utils/             # Helper functions
└── index.js           # Entry point
config/
tests/
package.json
.env.example
```

### Debugging
- ``console.log()`` for quick debugging
- Node.js inspector: ``node --inspect``
- Check if port is in use: ``port 3000``
- Use ``DEBUG=*`` environment variable for debug output
"@

    'perl' = @"
$commonHeader
## Language: Perl

### Running Perl
- ``perl script.pl`` - Run a script
- ``perl -c script.pl`` - Syntax check without running
- ``perl -w script.pl`` - Enable warnings
- ``perl -d script.pl`` - Run with debugger

### Code Style
- Always use ``use strict;`` and ``use warnings;``
- Use meaningful variable names
- Prefer lexical variables (my) over package variables
- Use 4-space indentation
- Document with POD

### Best Practices
```perl
#!/usr/bin/perl
use strict;
use warnings;
use feature 'say';       # Modern Perl features

# Always validate input
# Use proper error handling
die "Error: ..." if $error_condition;

# Use three-arg open
open my $fh, '<', $filename or die "Cannot open: $!";
```

### Module Management
- CPAN for modules: ``cpan install Module::Name``
- cpanminus (faster): ``cpanm Module::Name``
- Local modules with ``use lib 'lib';``
- Carton for dependency management (cpanfile)

### Common Patterns
```perl
# Hash reference
my $data = {
    key1 => 'value1',
    key2 => 'value2',
};

# Array reference  
my $list = [1, 2, 3];

# Subroutine
sub process_data {
    my ($arg1, $arg2) = @_;
    # ...
    return $result;
}
```

### File Structure
```
project/
├── lib/               # Perl modules (.pm)
├── bin/               # Executable scripts
├── t/                 # Tests
├── cpanfile           # Dependencies
├── Makefile.PL        # Build script
└── README
```

### Testing
- Use Test::More for tests
- Run tests: ``prove -l t/``
- Run single test: ``perl -Ilib t/test.t``

### Debugging
- ``use Data::Dumper; print Dumper($var);``
- ``perl -d script.pl`` for interactive debugger
- ``warn "Debug: $variable\n";`` for quick output
- Check error with ``$!`` after system calls
"@

    'python' = @"
$commonHeader
## Language: Python

### Running Python
- ``python script.py`` or ``py script.py`` (Windows)
- ``python -m module`` - Run module
- ``pip install package`` - Install package
- ``pip install -r requirements.txt`` - Install dependencies

### Code Style
- Follow PEP 8 style guide
- Use meaningful variable and function names
- Use type hints (Python 3.5+)
- Prefer f-strings for formatting
- Use virtual environments

### Best Practices
```python
#!/usr/bin/env python3
from typing import Optional, List

def process_data(items: List[str], limit: Optional[int] = None) -> dict:
    """Process items and return results.
    
    Args:
        items: List of items to process
        limit: Optional maximum items
        
    Returns:
        Dictionary with results
    """
    # Implementation
    return results

if __name__ == '__main__':
    main()
```

### Virtual Environments
```powershell
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### File Structure
```
project/
├── src/
│   └── package/
│       ├── __init__.py
│       └── module.py
├── tests/
├── requirements.txt
├── setup.py or pyproject.toml
└── README.md
```

### Testing
- pytest: ``pytest`` or ``python -m pytest``
- unittest: ``python -m unittest discover``

### Debugging
- ``print()`` for quick debugging
- ``breakpoint()`` for debugger (Python 3.7+)
- pdb: ``import pdb; pdb.set_trace()``
"@
}

# Detect language if auto
if ($Language -eq 'auto' -or [string]::IsNullOrEmpty($Language)) {
    $detected = Get-DetectedLanguage
    if ($detected) {
        $Language = $detected
        Write-Host "Detected project type: " -NoNewline -ForegroundColor Cyan
        Write-Host $Language -ForegroundColor Green
    } else {
        Write-Host "Could not auto-detect project type. Please specify: php, laravel, react, node, perl, python" -ForegroundColor Yellow
        exit 1
    }
}

# Get the template
if (-not $templates.ContainsKey($Language)) {
    Write-Host "Unknown language: $Language" -ForegroundColor Red
    Write-Host "Supported: php, laravel, symfony, react, node, perl, python" -ForegroundColor Yellow
    exit 1
}

$content = $templates[$Language]

# Write or append to file
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
