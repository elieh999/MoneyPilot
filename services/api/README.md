# MoneyPilot API

This directory contains the Python 3.12 and FastAPI service. It provides local
development endpoints for authentication, accounts, transactions, budgets,
bills, goals, dashboard summaries, synchronization experiments, and coach tools.

Money is represented as integer minor units. SQLite is the default development
database, and the same SQLAlchemy models support PostgreSQL through
configuration.

## Run locally

The repository helper is the shortest route:

```powershell
.\scripts\setup-dev.ps1
.\scripts\run-api.ps1 -SQLite
```

Open `http://127.0.0.1:8000/docs` for the interactive API reference.

To work from this directory directly:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
$env:MONEY_PILOT_DATABASE_URL = "sqlite:///./money_pilot.db"
$env:MONEY_PILOT_JWT_SECRET = "YOUR_32_PLUS_CHARACTER_RANDOM_SECRET_HERE"
uvicorn money_pilot_api.main:app --reload
```

The development seed endpoint is `POST /api/v1/dev/seed-demo`. It is unavailable
when `MONEY_PILOT_ENVIRONMENT=production`.

## Database and schema

Run migrations and check model parity with:

```powershell
alembic upgrade head
alembic check
```

`openapi.json` is the committed API schema. Regenerate it after route or schema
changes:

```powershell
python scripts/export_openapi.py
```

## Tests

```powershell
python -m pytest
```

The tests load the sibling financial core directly, so an editable package
installation is not required.

## Behavior worth preserving

- Cleared entries update posted and available balances.
- Pending entries update available balance only.
- Transfers update two owned accounts without affecting income or expense totals.
- Refunds and reimbursements reduce current period expenses.
- Safe to spend reserves unpaid bills and caller supplied obligations.
- Coach tools are allowlisted and checked against the authenticated owner.
- Budget suggestions remain drafts until the approval endpoint performs the write.

The Flutter client can log in to an API account and verify the current session
through `/auth/me`. It does not upload or download financial records. Financial
synchronization is tracked in [`docs/ROADMAP.md`](../../docs/ROADMAP.md).
