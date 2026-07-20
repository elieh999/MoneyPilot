# MoneyPilot

> Current release: **MoneyPilot 1.3.0** — complete English, French, and Arabic
> interface coverage, spending calendar, five color palettes, glow effects,
> secure financial-data wiping, and password-confirmed account deletion.

MoneyPilot is an offline-first personal-finance companion for mobile and
desktop. The product helps a person understand cash flow, plan salary, track
accounts and transactions, build budgets and goals, and ask a permissioned AI
coach for evidence-based explanations. It is not a bank, accounting package,
or substitute for professional financial, tax, investment, or legal advice.

This repository is a tested MVP foundation with a ready-to-run Windows desktop
build. The Flutter client now starts with no financial records, supports
password-protected local profiles and recovery codes, isolates each profile's
workspace, and includes a private conversational Local Coach. English, French,
and right-to-left Arabic are selectable in Settings, including multilingual
Coach replies. Cloud sync remains
an optional later integration; see the [deliverable status](docs/DELIVERABLE_STATUS.md)
for the exact implemented and deferred boundary.

The repository is organized as a monorepo:

- `apps/money_pilot`: Flutter client for Android, iOS, Windows, macOS, and Linux.
- `services/api`: FastAPI service and the server-owned authorization boundary.
- `packages/financial_core_python`: deterministic money calculations and tests.
- `packages/financial_contracts`: cross-runtime calculation test vectors.
- `infrastructure`: local Docker environment.
- `docs`: product and engineering contracts.
- `scripts`: Windows PowerShell developer helpers.

## Start locally

For the shortest handoff path, begin with [START_HERE.md](START_HERE.md).

Prerequisites: Git, Python 3.12+, Docker Desktop with Compose, and Flutter on
`PATH` (or `FLUTTER_ROOT` set to a standard Flutter SDK installation).

```powershell
Copy-Item .env.example .env
.\scripts\setup-dev.ps1
.\scripts\start-infra.ps1
```

Run the API and client in separate terminals:

```powershell
.\scripts\run-api.ps1
.\scripts\run-flutter.ps1
```

```powershell
testerrrrrrrrrrrrrrrrrrrrrrrrrr
```



API documentation is available at `http://localhost:8000/docs` when the API is
running. MinIO's console is at `http://localhost:9001`, and Mailpit is at
`http://localhost:8025`.

### Quick start without Docker

The API supports a local SQLite fallback, and the Flutter app runs locally
without the API. Docker is therefore recommended for the complete dependency
stack, not required for the first launch:

```powershell
.\scripts\setup-dev.ps1
.\scripts\run-api.ps1 -SQLite
```

In another terminal run `.\scripts\run-flutter.ps1`. The `-SQLite` switch
deliberately overrides the PostgreSQL URL copied from `.env` for that API process.

To run all available checks:

```powershell
.\scripts\check.ps1
```

See [Local setup](docs/LOCAL_SETUP.md) for manual commands and troubleshooting.
Never reuse the development credentials in a deployed environment.

## Scope and status

The canonical scope is defined in [Product specification](docs/PRODUCT_SPEC.md)
and staged in [MVP backlog](docs/MVP_BACKLOG.md). Phase 1 is a foundation, not a
claim that every advanced feature in the source briefs is implemented. The
repository must remain runnable and tested at every milestone.

## UI previews

[Desktop dashboard](docs/previews/money_pilot_desktop.png) and
[mobile onboarding](docs/previews/money_pilot_mobile.png) were rendered from the
tested Flutter widget tree. They are representative previews, not store assets.

## Engineering documentation

- [Architecture and diagrams](docs/ARCHITECTURE.md)
- [Repository structure](docs/REPOSITORY_STRUCTURE.md)
- [Primary user journeys](docs/USER_JOURNEYS.md)
- [MVP backlog and acceptance criteria](docs/MVP_BACKLOG.md)
- [Data model and ERD](docs/DATA_MODEL.md)
- [API modules](docs/API_OVERVIEW.md)
- [Financial calculations](docs/FINANCIAL_CALCULATIONS.md)
- [Offline synchronization](docs/OFFLINE_SYNC.md)
- [Security, privacy, and threat model](docs/SECURITY_PRIVACY.md)
- [AI tools and action approval](docs/AI_ARCHITECTURE.md)
- [Design system and screen map](docs/DESIGN_SYSTEM.md)
- [Testing guide](docs/TESTING.md)
- [Deployment](docs/DEPLOYMENT.md)
- [Release checklist](docs/RELEASE_CHECKLIST.md)
- [Roadmap and technical debt](docs/ROADMAP_TECHNICAL_DEBT.md)
- [Deliverable status](docs/DELIVERABLE_STATUS.md)
- [Verification record](VERIFICATION.md)
- [Security policy](SECURITY.md)
- [Third-party notices](THIRD_PARTY_NOTICES.md)

## Product invariants

1. Money is never represented with binary floating point.
2. Transfers never count as income or expense.
3. The local database is the client's source for rendering; sync is incremental.
4. Retried writes are idempotent and deletions use tombstones.
5. The API authorizes every resource by authenticated owner; client owner IDs
   are never trusted.
6. AI receives the minimum structured context required, cannot execute arbitrary
   SQL or code, and cannot mutate data without a fresh user approval.
7. Calculations expose inputs, assumptions, currency, rounding, and uncertainty.

## License and legal

MoneyPilot is released under the [MIT License](LICENSE). Third-party components
retain their own licenses as documented in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
Privacy-policy and terms text must be reviewed by qualified counsel before a
production or store release.
