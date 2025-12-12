<#
.SYNOPSIS
    Quick Laravel artisan command wrapper.

.DESCRIPTION
    Runs Laravel artisan commands with shorter syntax.
    Must be run from a Laravel project directory.

.PARAMETER Command
    The artisan command to run (e.g., migrate, make:model).

.PARAMETER Arguments
    Additional arguments to pass to artisan.

.EXAMPLE
    art migrate
    art make:model User -m
    art tinker
    art route:list
    art cache:clear
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command,

    [Parameter(Position = 1, ValueFromRemainingArguments)]
    [string[]]$Arguments
)

# Check for artisan
if (-not (Test-Path '.\artisan')) {
    Write-Host ""
    Write-Host "Not a Laravel project (artisan not found)" -ForegroundColor Red
    Write-Host ""
    exit 1
}

# No command - show help
if (-not $Command) {
    Write-Host ""
    Write-Host "Laravel Artisan Helper" -ForegroundColor Cyan
    Write-Host "=====================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Common commands:" -ForegroundColor Yellow
    Write-Host "  art migrate              Run migrations"
    Write-Host "  art migrate:fresh        Drop all and re-run migrations"
    Write-Host "  art migrate:rollback     Rollback last migration"
    Write-Host "  art make:model Name -m   Create model with migration"
    Write-Host "  art make:controller Name Create controller"
    Write-Host "  art make:migration name  Create migration"
    Write-Host "  art tinker               Interactive REPL"
    Write-Host "  art serve                Start dev server"
    Write-Host "  art route:list           List all routes"
    Write-Host "  art cache:clear          Clear app cache"
    Write-Host "  art config:clear         Clear config cache"
    Write-Host "  art view:clear           Clear view cache"
    Write-Host "  art optimize:clear       Clear all caches"
    Write-Host "  art queue:work           Start queue worker"
    Write-Host "  art schedule:run         Run scheduled tasks"
    Write-Host "  art test                 Run tests"
    Write-Host ""
    Write-Host "Run " -NoNewline -ForegroundColor Gray
    Write-Host "art list" -NoNewline -ForegroundColor Yellow
    Write-Host " to see all available commands." -ForegroundColor Gray
    Write-Host ""
    exit 0
}

# Build command
$artisanArgs = @($Command) + $Arguments

Write-Host ""
Write-Host "php artisan $($artisanArgs -join ' ')" -ForegroundColor DarkGray
Write-Host ""

# Run artisan
php artisan @artisanArgs
