param([switch]$RemoveVolumes)

. (Join-Path $PSScriptRoot "_common.ps1")

$arguments = @("down", "--remove-orphans")
if ($RemoveVolumes) {
    $confirmation = Read-Host "Delete PostgreSQL, Redis, and MinIO development volumes? Type DELETE"
    if ($confirmation -ne "DELETE") {
        throw "Volume deletion cancelled."
    }
    $arguments += "--volumes"
}
Invoke-MoneyPilotCompose -Arguments $arguments
