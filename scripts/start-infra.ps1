. (Join-Path $PSScriptRoot "_common.ps1")

Invoke-MoneyPilotCompose -Arguments @(
    "up", "-d", "postgres", "redis", "minio", "mailpit"
)
Write-Host "Infrastructure is starting. Inspect with: docker compose -f infrastructure/docker-compose.yml ps"
