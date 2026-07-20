param(
    [string]$Device,
    [switch]$SkipPubGet
)

. (Join-Path $PSScriptRoot "_common.ps1")
Import-MoneyPilotEnv

$root = Get-RepositoryRoot
$appRoot = Join-Path $root "apps\money_pilot"
if (-not (Test-Path -LiteralPath (Join-Path $appRoot "pubspec.yaml"))) {
    throw "Flutter application was not found at apps/money_pilot."
}
$flutter = Get-MoneyPilotFlutter

Push-Location $appRoot
try {
    if (-not $SkipPubGet) {
        & $flutter pub get
        if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed." }
    }
    $arguments = @("run")
    if ($Device) { $arguments += @("-d", $Device) }
    & $flutter @arguments
} finally {
    Pop-Location
}
