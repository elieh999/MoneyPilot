. (Join-Path $PSScriptRoot "_common.ps1")

$root = Get-RepositoryRoot
$python = Get-MoneyPilotPython
$testPaths = @()
foreach ($candidate in @(
    "packages\financial_core_python\tests",
    "services\api\tests"
)) {
    $path = Join-Path $root $candidate
    if (Test-Path -LiteralPath $path) { $testPaths += $path }
}
if ($testPaths.Count -gt 0) {
    & $python -m pytest @testPaths
    if ($LASTEXITCODE -ne 0) { throw "Python tests failed." }
}

$ruffAvailable = (& $python -c "import importlib.util; print(bool(importlib.util.find_spec('ruff')))" 2>$null) -eq "True"
if ($ruffAvailable) {
    $pythonTargets = @()
    foreach ($candidate in @("services\api", "packages\financial_core_python")) {
        $path = Join-Path $root $candidate
        if (Test-Path -LiteralPath $path) { $pythonTargets += $path }
    }
    & $python -m ruff format --check @pythonTargets
    if ($LASTEXITCODE -ne 0) { throw "Python format check failed." }
    & $python -m ruff check @pythonTargets
    if ($LASTEXITCODE -ne 0) { throw "Python lint failed." }
} else {
    Write-Warning "ruff is not installed locally; CI still runs Python format and lint checks."
}

$flutterApp = Join-Path $root "apps\money_pilot"
if (Test-Path -LiteralPath (Join-Path $flutterApp "pubspec.yaml")) {
    $flutter = Get-MoneyPilotFlutter
    $dart = Get-MoneyPilotDart
    Push-Location $flutterApp
    try {
        & $flutter pub get
        if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed." }
        & $dart format --output=none --set-exit-if-changed .
        if ($LASTEXITCODE -ne 0) { throw "Dart format check failed." }
        & $flutter analyze
        if ($LASTEXITCODE -ne 0) { throw "Flutter analysis failed." }
        & $flutter test
        if ($LASTEXITCODE -ne 0) { throw "Flutter tests failed." }
    } finally {
        Pop-Location
    }
}

Write-Host "All available checks passed."
