param(
    [switch]$NoReload,
    [switch]$SQLite
)

. (Join-Path $PSScriptRoot "_common.ps1")
Import-MoneyPilotEnv

if ($SQLite) {
    $env:MONEY_PILOT_DATABASE_URL = "sqlite:///./money_pilot.db"
}

$root = Get-RepositoryRoot
$python = Get-MoneyPilotPython
$apiRoot = Join-Path $root "services\api"
$packageMain = Join-Path $apiRoot "src\money_pilot_api\main.py"
$fallbackMain = Join-Path $apiRoot "app\main.py"

if (Test-Path -LiteralPath $packageMain) {
    $application = "money_pilot_api.main:app"
    $sourcePaths = @(
        (Join-Path $apiRoot "src"),
        (Join-Path $root "packages\financial_core_python\src")
    )
    if ($env:PYTHONPATH) { $sourcePaths += $env:PYTHONPATH }
    $env:PYTHONPATH = $sourcePaths -join [IO.Path]::PathSeparator
} elseif (Test-Path -LiteralPath $fallbackMain) {
    $application = "app.main:app"
} else {
    throw "No FastAPI entrypoint found (expected src/money_pilot_api/main.py or app/main.py)."
}

$hostName = if ($env:MONEY_PILOT_API_HOST) { $env:MONEY_PILOT_API_HOST } else { "127.0.0.1" }
$port = if ($env:MONEY_PILOT_API_PORT) { $env:MONEY_PILOT_API_PORT } else { "8000" }
$arguments = @("-m", "uvicorn", $application, "--host", $hostName, "--port", $port)
if (-not $NoReload) { $arguments += "--reload" }

Push-Location $apiRoot
try {
    & $python @arguments
} finally {
    Pop-Location
}
