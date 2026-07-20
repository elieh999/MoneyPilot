# MoneyPilot API

Functional Python 3.12/FastAPI backend for the first MoneyPilot milestone. It
implements Argon2id password hashing, rotating JWT-style sessions, UUID ownership,
balance-aware transactions and transfers, budgets, bills, goals, dashboard and
safe-to-spend summaries, persisted sync operations, and an AI tool/action-draft
boundary with a deterministic no-network provider.

All money is represented as integer minor units. The API uses SQLite by default
and the same SQLAlchemy 2.x models support PostgreSQL through
`postgresql+psycopg://...` configuration.

## Run locally

From `services/api` in PowerShell:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
Copy-Item .env.example .env
$env:MONEY_PILOT_DATABASE_URL = "sqlite:///./money_pilot.db"
$env:MONEY_PILOT_JWT_SECRET = "YOUR_32_PLUS_CHARACTER_RANDOM_SECRET_HERE"
uvicorn money_pilot_api.main:app --reload
```

Open `http://127.0.0.1:8000/docs` for OpenAPI. Create repeatable sample data with
`POST /api/v1/dev/seed-demo`; the response returns development-only credentials.
The endpoint returns 404 when `MONEY_PILOT_ENVIRONMENT=production`.

The checked schema is `openapi.json`. Regenerate it deterministically after API
changes with `python scripts/export_openapi.py`.

For PostgreSQL, install the same requirements and set:

```powershell
$env:MONEY_PILOT_DATABASE_URL = "postgresql+psycopg://money_pilot:YOUR_POSTGRES_PASSWORD@localhost:5432/money_pilot"
```

## Run tests

```powershell
python -m pytest
```

Create or upgrade the configured database with `alembic upgrade head`; verify
model/migration parity with `alembic check`.

The test bootstrap loads the sibling financial-core source directly, so tests
also run before editable installation. Production deployments must set a unique
JWT secret and should run managed migrations instead of automatic schema
creation; Alembic migration packaging belongs to the infrastructure milestone.

## Transaction and calculation policy

- Cleared entries update posted and available balances; pending entries update
  available balance only.
- Transfers debit one owned account and credit another without affecting income
  or expense totals. Both accounts are validated before mutation.
- Refunds and reimbursements offset current-period expenses rather than inflate
  income; the resulting expense total is floored at zero.
- Safe-to-spend starts from included available balances, so pending local entries
  are not subtracted a second time. It then reserves unpaid bills and caller-
  supplied obligations/buffers. A negative raw result is exposed as a shortfall.
- AI-selected tools are allowlisted and server-authorized. The local provider can
  create a ten-minute, action/payload-hash-bound proposal, but only the approval
  endpoint performs the one-time write. Opaque signed approval tokens remain a
  production-hardening follow-up.
