. (Join-Path $PSScriptRoot "_common.ps1")

Invoke-MoneyPilotCompose -Arguments @("up", "-d", "--build")
Write-Host "Stack is starting. API docs: http://localhost:8000/docs"
