BeforeDiscovery {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    $moduleDir = Join-Path $repoRoot "PowerShellDevToolkit"
    $publicDir = Join-Path $moduleDir "Public"
    $allScripts = @(Get-ChildItem "$publicDir\*.ps1" -File) + @(Get-ChildItem (Join-Path $moduleDir "Private\*.ps1") -File)
}

BeforeAll {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    $moduleDir = Join-Path $repoRoot "PowerShellDevToolkit"
    $publicDir = Join-Path $moduleDir "Public"
    Import-Module $moduleDir -Force
}

Describe "Bug Fix: Copy-ToClipboard parameter alias conflict (#1)" {
    It "Should parse without errors" {
        $errors = $null
        [System.Management.Automation.PSParser]::Tokenize(
            (Get-Content "$publicDir\Copy-ToClipboard.ps1" -Raw), [ref]$errors
        ) | Out-Null
        $errors.Count | Should -Be 0
    }

    It "Should not have Path as an alias on PathOnly switch" {
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            "$publicDir\Copy-ToClipboard.ps1", [ref]$null, [ref]$null
        )
        $functions = $ast.FindAll({ param($a) $a -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
        $fn = $functions | Where-Object { $_.Name -eq 'Copy-ToClipboard' }
        $params = $fn.Body.ParamBlock.Parameters
        $pathOnly = $params | Where-Object { $_.Name.VariablePath.UserPath -eq 'PathOnly' }
        $aliases = $pathOnly.Attributes | Where-Object { $_.TypeName.Name -eq 'Alias' }
        $hasPathAlias = $false
        if ($aliases) {
            $aliasValues = $aliases.PositionalArguments | ForEach-Object { $_.Value }
            $hasPathAlias = $aliasValues -contains 'Path'
        }
        $hasPathAlias | Should -Be $false
    }

    It "Should have both Path and PathOnly as distinct parameters" {
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            "$publicDir\Copy-ToClipboard.ps1", [ref]$null, [ref]$null
        )
        $functions = $ast.FindAll({ param($a) $a -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
        $fn = $functions | Where-Object { $_.Name -eq 'Copy-ToClipboard' }
        $paramNames = $fn.Body.ParamBlock.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath }
        ($paramNames -contains 'Path') | Should -Be $true
        ($paramNames -contains 'PathOnly') | Should -Be $true
    }
}

Describe "Bug Fix: Get-GitQuick subdirectory detection (#2)" {
    It "Should use git rev-parse instead of Test-Path .git" {
        $content = Get-Content "$publicDir\Get-GitQuick.ps1" -Raw
        ($content -match 'git rev-parse --is-inside-work-tree') | Should -Be $true
        ($content -match "Test-Path '\.git'") | Should -Be $false
    }

    It "Should parse without errors" {
        $errors = $null
        [System.Management.Automation.PSParser]::Tokenize(
            (Get-Content "$publicDir\Get-GitQuick.ps1" -Raw), [ref]$errors
        ) | Out-Null
        $errors.Count | Should -Be 0
    }

    It "Should work from a git repo subdirectory" {
        $testDir = Join-Path $env:TEMP "pester-git-subdir-$(Get-Random)"
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null
        Push-Location $testDir
        try {
            git init . 2>$null | Out-Null
            git config user.email "test@test.com" 2>$null
            git config user.name "Test" 2>$null
            git commit --allow-empty -m "init" 2>$null | Out-Null
            $subDir = Join-Path $testDir "sub"
            New-Item -Path $subDir -ItemType Directory -Force | Out-Null
            Push-Location $subDir
            try {
                $raw = Get-GitQuick -AsJson 2>$null
                $output = $raw | ConvertFrom-Json
                $output.branch | Should -Not -BeNullOrEmpty
            } finally {
                Pop-Location
            }
        } finally {
            Pop-Location
            Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should report error for non-git directory" {
        $testDir = Join-Path $env:TEMP "pester-no-git-$(Get-Random)"
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null
        Push-Location $testDir
        try {
            $raw = Get-GitQuick -AsJson 2>$null
            $parsed = $raw | ConvertFrom-Json
            $parsed.error | Should -Be 'Not a git repository'
        } finally {
            Pop-Location
            Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe "Bug Fix: Find-InProject removed unused -Context param (#3)" {
    It "Should not accept a -Context parameter" {
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            "$publicDir\Find-InProject.ps1", [ref]$null, [ref]$null
        )
        $functions = $ast.FindAll({ param($a) $a -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
        $fn = $functions | Where-Object { $_.Name -eq 'Find-InProject' }
        $paramNames = $fn.Body.ParamBlock.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath }
        ($paramNames -contains 'Context') | Should -Be $false
    }

    It "Should still accept required parameters" {
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            "$publicDir\Find-InProject.ps1", [ref]$null, [ref]$null
        )
        $functions = $ast.FindAll({ param($a) $a -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
        $fn = $functions | Where-Object { $_.Name -eq 'Find-InProject' }
        $paramNames = $fn.Body.ParamBlock.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath }
        ($paramNames -contains 'Pattern') | Should -Be $true
        ($paramNames -contains 'Type') | Should -Be $true
        ($paramNames -contains 'Path') | Should -Be $true
        ($paramNames -contains 'AsJson') | Should -Be $true
    }
}

Describe "Bug Fix: Get-ProjectContext Vue detection (#4)" {
    It "Should detect Vue-only project (no React)" {
        $projDir = Join-Path $env:TEMP "pester-vue-$(Get-Random)"
        New-Item -Path $projDir -ItemType Directory -Force | Out-Null
        try {
            @{ dependencies = @{ vue = "^3.0.0" } } | ConvertTo-Json | Set-Content "$projDir\package.json"
            $raw = Get-ProjectContext -Path $projDir -AsJson 2>$null
            $output = $raw | ConvertFrom-Json
            $output.framework | Should -Be 'Vue'
            $output.type | Should -Be 'JavaScript/Node'
        } finally {
            Remove-Item $projDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should detect Nuxt project" {
        $projDir = Join-Path $env:TEMP "pester-nuxt-$(Get-Random)"
        New-Item -Path $projDir -ItemType Directory -Force | Out-Null
        try {
            @{ dependencies = @{ vue = "^3.0.0"; nuxt = "^3.0.0" } } | ConvertTo-Json | Set-Content "$projDir\package.json"
            $raw = Get-ProjectContext -Path $projDir -AsJson 2>$null
            $output = $raw | ConvertFrom-Json
            $output.framework | Should -Be 'Nuxt'
        } finally {
            Remove-Item $projDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should detect React without confusing with Vue" {
        $projDir = Join-Path $env:TEMP "pester-react-$(Get-Random)"
        New-Item -Path $projDir -ItemType Directory -Force | Out-Null
        try {
            @{ dependencies = @{ react = "^18.0.0" } } | ConvertTo-Json | Set-Content "$projDir\package.json"
            $raw = Get-ProjectContext -Path $projDir -AsJson 2>$null
            $output = $raw | ConvertFrom-Json
            $output.framework | Should -Be 'React'
        } finally {
            Remove-Item $projDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "Should detect Next.js project" {
        $projDir = Join-Path $env:TEMP "pester-nextjs-$(Get-Random)"
        New-Item -Path $projDir -ItemType Directory -Force | Out-Null
        try {
            @{ dependencies = @{ react = "^18.0.0"; next = "^14.0.0" } } | ConvertTo-Json | Set-Content "$projDir\package.json"
            $raw = Get-ProjectContext -Path $projDir -AsJson 2>$null
            $output = $raw | ConvertFrom-Json
            $output.framework | Should -Be 'Next.js'
        } finally {
            Remove-Item $projDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe "Bug Fix: Setup-Environment Write-Warning shadow (#5)" {
    It "Should not define a function named Write-Warning" {
        $content = Get-Content "$repoRoot\Setup-Environment.ps1" -Raw
        ($content -match 'function Write-Warning\b') | Should -Be $false
    }

    It "Should define Write-Warn instead" {
        $content = Get-Content "$repoRoot\Setup-Environment.ps1" -Raw
        ($content -match 'function Write-Warn\b') | Should -Be $true
    }

    It "Should not call Write-Warning anywhere" {
        $lines = Get-Content "$repoRoot\Setup-Environment.ps1"
        $badCalls = $lines | Where-Object { $_ -match 'Write-Warning\s' -and $_ -notmatch 'function Write-Warning' }
        ($badCalls | Measure-Object).Count | Should -Be 0
    }
}

Describe "Bug Fix: Set-ProjectEnv dead script variable (#6)" {
    It 'Should not use $script:LoadedEnvVars' {
        $content = Get-Content "$publicDir\Set-ProjectEnv.ps1" -Raw
        ($content -match '\$script:LoadedEnvVars') | Should -Be $false
    }

    It 'Should initialize $global:LoadedEnvVars' {
        $content = Get-Content "$publicDir\Set-ProjectEnv.ps1" -Raw
        ($content -match '\$global:LoadedEnvVars') | Should -Be $true
    }
}

Describe "General: All module scripts parse without syntax errors" {
    It "Should parse <Name> without errors" -ForEach ($allScripts | ForEach-Object { @{ Name = $_.Name; FullName = $_.FullName } }) {
        $errors = $null
        [System.Management.Automation.PSParser]::Tokenize(
            (Get-Content $FullName -Raw), [ref]$errors
        ) | Out-Null
        $errors.Count | Should -Be 0
    }
}

Describe "General: No empty if/else blocks in any module script" {
    It "Should have no empty branches in <Name>" -ForEach ($allScripts | ForEach-Object { @{ Name = $_.Name; FullName = $_.FullName } }) {
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $FullName, [ref]$null, [ref]$null
        )
        $ifStatements = $ast.FindAll({ param($a) $a -is [System.Management.Automation.Language.IfStatementAst] }, $true)
        $emptyCount = 0
        foreach ($ifStmt in $ifStatements) {
            foreach ($clause in $ifStmt.Clauses) {
                if ($clause.Item2.Statements.Count -eq 0 -and $clause.Item2.Traps.Count -eq 0) {
                    $emptyCount++
                }
            }
            if ($ifStmt.ElseClause -and $ifStmt.ElseClause.Statements.Count -eq 0 -and $ifStmt.ElseClause.Traps.Count -eq 0) {
                $emptyCount++
            }
        }
        $emptyCount | Should -Be 0
    }
}
