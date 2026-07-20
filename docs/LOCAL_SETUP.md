# Local development setup

These instructions target Windows PowerShell. Standard Flutter and Python tools
are used; no workspace-specific SDK path is committed.

## Prerequisites

- Git.
- Python 3.12 or newer (`python --version` or the Windows `py` launcher).
- Docker Desktop with Compose (`docker compose version`).
- Flutter stable on `PATH`; alternatively set `FLUTTER_ROOT` to your Flutter SDK.
- Platform toolchain for the target device: Android Studio/SDK, Xcode on macOS,
  Visual Studio Desktop development with C++ on Windows, or Linux desktop deps.

Verify Flutter separately:

```powershell
flutter doctor -v
flutter devices
```

## Automated setup

```powershell
Copy-Item .env.example .env
.\scripts\setup-dev.ps1
.\scripts\start-infra.ps1
```

Review `.env`; its credentials are deliberately local-only. The setup script
creates `.venv`, installs `services/api/requirements.txt` or the API `pyproject`,
and runs `flutter pub get` when the Flutter project exists.

Run in separate terminals:

```powershell
.\scripts\run-api.ps1
.\scripts\run-flutter.ps1 -Device windows
```

Omit `-Device windows` to let Flutter choose/interactively request a device.
`run-api.ps1` imports `.env`, prefers `money_pilot_api.main:app`, and enables
reload. Pass `-NoReload` for a single process.

## Quick start without Docker

Docker is recommended for PostgreSQL, Redis, MinIO, and Mailpit, but it is not
required to explore the current local-first milestone. The API supports SQLite,
and the Flutter prototype can run with its device-local demo data:

```powershell
.\scripts\setup-dev.ps1
.\scripts\run-api.ps1 -SQLite
```

Then, in another terminal:

```powershell
.\scripts\run-flutter.ps1 -Device windows
```

`-SQLite` overrides `MONEY_PILOT_DATABASE_URL` for that API process even when
`.env` contains the normal PostgreSQL URL. SQLite is a development fallback;
PostgreSQL remains required for production-parity migration, concurrency, and
sync verification. The Flutter demo can also be opened without the API, but that
does not validate authentication or synchronization.

## Manual setup

```powershell
Copy-Item .env.example .env
docker compose --env-file .env -f infrastructure\docker-compose.yml up -d postgres redis minio mailpit

python -m venv .venv
.\.venv\Scripts\python.exe -m pip install --upgrade pip
Push-Location services\api
..\..\.venv\Scripts\python.exe -m pip install -r requirements.txt
$env:PYTHONPATH = (Resolve-Path .\src)
..\..\.venv\Scripts\python.exe -m uvicorn money_pilot_api.main:app --reload --host 127.0.0.1 --port 8000
Pop-Location
```

In another terminal:

```powershell
Set-Location apps\money_pilot
flutter pub get
flutter run -d windows
```

Use `flutter run -d android`, an emulator/device ID from `flutter devices`, or a
supported desktop target. iOS/macOS builds require macOS.

## Containerized API

To build and start the API with all local dependencies:

```powershell
.\scripts\start-stack.ps1
```

The image builds from repository root because API requirements reference the
shared financial-core package. This Compose file is development-only.

## Local endpoints

| Service | Address |
|---|---|
| API | `http://localhost:8000` |
| OpenAPI UI | `http://localhost:8000/docs` |
| Liveness / readiness | `http://localhost:8000/health/live` / `http://localhost:8000/health/ready` |
| PostgreSQL | `localhost:5432` |
| Redis | `localhost:6379` |
| MinIO API / console | `http://localhost:9000` / `http://localhost:9001` |
| Mailpit SMTP / UI | `localhost:1025` / `http://localhost:8025` |

The safe AI default is `MONEY_PILOT_AI_PROVIDER=disabled`. Set provider-neutral
base URL/model/key only for an adapter actually implemented and never commit the
key. Core application startup must not require an AI credential.

## Stop and reset

```powershell
.\scripts\stop-dev.ps1
```

`-RemoveVolumes` permanently deletes local PostgreSQL, Redis, and MinIO volumes
after a typed confirmation. It does not remove `.venv` or local Flutter state.

## Troubleshooting

- **Port in use:** change the matching port in `.env`, then restart Compose.
- **Docker unhealthy:** run
  `docker compose -f infrastructure\docker-compose.yml ps` and inspect the
  individual service logs.
- **API import error:** rerun setup, confirm `.venv` and `services/api/src`, and
  launch through `scripts/run-api.ps1` so `PYTHONPATH` is set.
- **PostgreSQL authentication failure:** environment changes do not rewrite an
  existing volume. Use the prior credentials or deliberately remove development
  volumes after confirming no needed data remains.
- **Flutter device missing:** run `flutter doctor -v`, enable the desktop target
  if applicable, and install the target platform toolchain.
- **PowerShell says scripts are disabled:** use a process-scoped policy for the
  current terminal (`Set-ExecutionPolicy -Scope Process Bypass`) or invoke a
  helper with `powershell -NoProfile -ExecutionPolicy Bypass -File ...`. Do not
  weaken the machine/user policy globally for this project.
- **AI unavailable:** expected when disabled/offline; it must not affect ledger
  or planning features.

No permanent shared demo password is committed. Development users should be
created through registration or deterministic test factories once the relevant
milestone is implemented.
