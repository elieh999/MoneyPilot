param(
    [switch]$SkipPython,
    [switch]$SkipFlutter
)

. (Join-Path $PSScriptRoot "_common.ps1")

$root = Get-RepositoryRoot
$envPath = Join-Path $root ".env"
if (-not (Test-Path -LiteralPath $envPath)) {
    Copy-Item -LiteralPath (Join-Path $root ".env.example") -Destination $envPath
    Write-Host "Created .env from .env.example. Development values only; review before use."
}

if (-not $SkipPython) {
    $venvPython = Join-Path $root ".venv\Scripts\python.exe"
    if (-not (Test-Path -LiteralPath $venvPython)) {
        $pythonCommand = Get-Command python -ErrorAction SilentlyContinue
        if ($pythonCommand) {
            & $pythonCommand.Source -m venv (Join-Path $root ".venv")
        } else {
            $pyLauncher = Get-Command py -ErrorAction SilentlyContinue
            if (-not $pyLauncher) {
                throw "Python 3.12+ was not found."
            }
            & $pyLauncher.Source -3.12 -m venv (Join-Path $root ".venv")
        }
    }
    & $venvPython -m pip install --upgrade pip
    Push-Location (Join-Path $root "services\api")
    try {
        if (Test-Path -LiteralPath "requirements.txt") {
            & $venvPython -m pip install -r requirements.txt
        } elseif (Test-Path -LiteralPath "pyproject.toml") {
            & $venvPython -m pip install -e ".[dev]"
        } else {
            throw "services/api has neither requirements.txt nor pyproject.toml."
        }
    } finally {
        Pop-Location
    }
}

$flutterApp = Join-Path $root "apps\money_pilot"
if (-not $SkipFlutter -and (Test-Path -LiteralPath (Join-Path $flutterApp "pubspec.yaml"))) {
    $flutter = Get-MoneyPilotFlutter
    Push-Location $flutterApp
    try {
        & $flutter pub get
        if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed." }
    } finally {
        Pop-Location
    }
}

Write-Host "Development dependencies are ready. Start infrastructure with .\scripts\start-infra.ps1."
