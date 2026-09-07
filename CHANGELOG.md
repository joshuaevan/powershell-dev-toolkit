# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and versions follow
[Semantic Versioning](https://semver.org/).

## [1.2.0] - 2026-09-04

Gallery-native release: everything that used to require a git clone now works
on a PowerShell Gallery install.

### Added
- `Initialize-Toolkit`: first-run setup that creates the data folder, copies
  `config.example.json` to `config.json`, creates the `creds` folder and opens
  the config in your editor. Works for git-clone and Gallery installs.
- `New-SSHCredential`: prompts for an SSH username/password and stores it
  DPAPI-encrypted in the creds folder. Replaces the manual `Export-Clixml` steps.
- Tab completion for SSH server aliases on `cssh` / `tunnel` / `Connect-SSH` /
  `Connect-SSHTunnel`, and for database names on the tunnel port argument.
- `PSDT_HOME` environment variable to override where config and creds live.
- `PSDT_SKIP_UPDATE_CHECK` environment variable to disable the startup update check.
- `helpme` shows the install type and the resolved `config.json` path.
- This changelog.

### Changed
- Config and credentials now resolve through a single data folder: the repo root
  for git clones (unchanged), `%LOCALAPPDATA%\PowerShellDevToolkit` for Gallery
  installs, or `PSDT_HOME` when set.
- `config.example.json` moved from the repo root into the module folder so it
  ships in the Gallery package.
- `Update-Toolkit` and the startup update check detect Gallery installs and
  compare against the Gallery, updating with `Update-Module` / `Update-PSResource`.
- A missing `config.json` no longer prompts from inside other commands; commands
  print where they looked and point to `Initialize-Toolkit`.
- `e` / `Edit-File` no longer prints a config warning when `config.json` is absent.

### Fixed
- Gallery installs could not locate `config.json`, the `creds` folder or
  `config.example.json`, and `Update-Toolkit` failed with "not a git repository".

### Internal
- Shared `Resolve-SSHTarget` and `Test-WslAvailable` helpers replace about 100
  duplicated lines in `Connect-SSH` and `Connect-SSHTunnel`.
- New `Get-ToolkitPaths` helper is the single source of truth for on-disk paths.
- 50+ new Pester tests; Gallery behavior is tested with mocks, never the network.

## [1.1.0] - 2026-04-09

### Added
- Proper PowerShell module (`PowerShellDevToolkit`) with manifest, Public/Private
  layout and exported aliases; published to the PowerShell Gallery.
- All commands from the documentation implemented as module functions.
- `Update-Toolkit` self-update and daily startup update check.
- Pester 5 test suite and GitHub Actions CI on Windows.
- Logo assets in README, setup and `helpme`.

### Fixed
- Multiple bugs found in code review and by the new tests (parameter alias
  conflict in `Copy-ToClipboard`, git detection from subdirectories, Vue/Nuxt
  detection, `Write-Warning` shadowing in setup, `Set-ProjectEnv` scope bug).

## [1.0.0] - 2025-12-11

### Added
- Initial release as a collection of standalone scripts: SSH connect and tunnel
  with credential and key-file support, dev server launcher, port tools, project
  detection, AI rules generation, log tailing and quick utilities.
