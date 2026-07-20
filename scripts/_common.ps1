Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-RepositoryRoot {
    return (Split-Path -Parent $PSScriptRoot)
}

function Import-MoneyPilotEnv {
    param([string]$Path = (Join-Path (Get-RepositoryRoot) ".env"))

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    foreach ($line in Get-Content -LiteralPath $Path) {
        $trimmed = $line.Trim()
        if (-not $trimmed -or $trimmed.StartsWith("#") -or -not $trimmed.Contains("=")) {
            continue
        }
        $parts = $trimmed.Split("=", 2)
        $name = $parts[0].Trim()
        $value = $parts[1].Trim()
        if ($name -match '^[A-Za-z_][A-Za-z0-9_]*$') {
            [Environment]::SetEnvironmentVariable($name, $value, "Process")
        }
    }
}

function Get-MoneyPilotPython {
    $root = Get-RepositoryRoot
    $venvPython = Join-Path $root ".venv\Scripts\python.exe"
    if (Test-Path -LiteralPath $venvPython) {
        return $venvPython
    }
    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($python) {
        return $python.Source
    }
    throw "Python was not found. Install Python 3.12+ and run .\scripts\setup-dev.ps1."
}

function Get-MoneyPilotFlutter {
    $flutter = Get-Command flutter -ErrorAction SilentlyContinue
    if ($flutter) {
        return $flutter.Source
    }
    if ($env:FLUTTER_ROOT) {
        $candidate = Join-Path $env:FLUTTER_ROOT "bin\flutter.bat"
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }
    throw "Flutter was not found on PATH. Install Flutter or set FLUTTER_ROOT."
}

function Get-MoneyPilotDart {
    $dart = Get-Command dart -ErrorAction SilentlyContinue
    if ($dart) {
        return $dart.Source
    }
    $flutter = Get-MoneyPilotFlutter
    $candidate = Join-Path (Split-Path -Parent $flutter) "dart.bat"
    if (Test-Path -LiteralPath $candidate) {
        return $candidate
    }
    throw "Dart was not found next to the Flutter executable."
}

function Invoke-MoneyPilotCompose {
    param([Parameter(Mandatory)][string[]]$Arguments)

    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw "Docker was not found. Install and start Docker Desktop."
    }
    $root = Get-RepositoryRoot
    $composeFile = Join-Path $root "infrastructure\docker-compose.yml"
    $composeArgs = @("compose")
    $envFile = Join-Path $root ".env"
    if (Test-Path -LiteralPath $envFile) {
        $composeArgs += @("--env-file", $envFile)
    }
    $composeArgs += @("-f", $composeFile)
    $composeArgs += $Arguments
    & docker @composeArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Docker Compose failed with exit code $LASTEXITCODE."
    }
}
