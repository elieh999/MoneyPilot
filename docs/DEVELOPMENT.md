# Development

MoneyPilot uses Flutter for the client and Python 3.12 with FastAPI for the API.
The helper scripts in `scripts` are written for Windows PowerShell.

## Prerequisites

Install Git, Python 3.12 or newer, and Flutter stable. Building a native client
also requires the toolchain for that platform. On Windows, install the Visual
Studio Desktop development with C++ workload.

Docker Desktop is optional. It is useful when working with PostgreSQL, Redis,
MinIO, and Mailpit, but SQLite is enough for the first API run.

Check the Flutter installation with:

```powershell
flutter doctor -v
flutter devices
```

## Setup

From the repository root:

```powershell
.\scripts\setup-dev.ps1
```

The setup script creates `.env` from `.env.example` when needed, creates a
Python virtual environment, installs API dependencies, and runs `flutter pub
get`. The values in `.env.example` are for local development only.

## Running with SQLite

Start the API:

```powershell
.\scripts\run-api.ps1 -SQLite
```

The OpenAPI page is available at `http://127.0.0.1:8000/docs`.

Start the Flutter client in another terminal:

```powershell
.\scripts\run-flutter.ps1
```

Use the `-Device` parameter when more than one Flutter target is available:

```powershell
.\scripts\run-flutter.ps1 -Device windows
```

## Running the Docker services

```powershell
.\scripts\start-infra.ps1
.\scripts\run-api.ps1
```

Stop the local services with:

```powershell
.\scripts\stop-dev.ps1
```

## Tests

Run the full local check script:

```powershell
.\scripts\check.ps1
```

This covers Python tests, Ruff formatting and linting, Dart formatting, Flutter
analysis, and Flutter tests when the required tools are installed.

Run one side of the project directly when working on a focused change:

```powershell
.\.venv\Scripts\python.exe -m pytest services\api\tests packages\financial_core_python\tests

Set-Location apps\money_pilot
flutter test
```

## Generated API schema

`services/api/openapi.json` is committed so API changes are reviewable. Regenerate
it after changing routes or schemas:

```powershell
Set-Location services\api
..\..\.venv\Scripts\python.exe scripts\export_openapi.py
```

## Local files

Do not commit `.env`, local databases, virtual environments, Flutter build
output, editor settings, or application logs. The root `.gitignore` already
covers these files.

## Common problems

- If Python is not found, install Python 3.12 and reopen PowerShell.
- If Flutter reports no desktop device, enable the target platform and install
  its native build tools.
- If port 8000 is busy, stop the earlier API process or change
  `MONEY_PILOT_API_PORT` in the local environment.
- If the API cannot reach PostgreSQL, use `-SQLite` or start Docker Desktop.
