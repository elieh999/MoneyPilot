# Testing guide

## Quality strategy

Test deterministic domain rules heavily, repositories/services at real database
boundaries, API ownership and error contracts, Flutter state/UI behavior, and a
small number of high-value end-to-end journeys. Mock only external providers;
do not mock the financial core in integration tests.

## Run all available local checks

From the repository root after `scripts/setup-dev.ps1`:

```powershell
.\scripts\check.ps1
```

The helper discovers existing API/core test directories, runs Python tests,
runs Ruff when installed, then runs Dart format, Flutter analysis, and Flutter
tests when the client is present.

## Python

```powershell
.\.venv\Scripts\python.exe -m pytest packages\financial_core_python\tests services\api\tests -ra
.\.venv\Scripts\python.exe -m ruff format --check services\api packages\financial_core_python
.\.venv\Scripts\python.exe -m ruff check services\api packages\financial_core_python
```

Required layers:

- Financial core: table/property tests for formulas, integer boundaries,
  rounding, every currency scale, date/time edges, and invariant failures.
- Service/repository: transactions, ownership scopes, optimistic concurrency,
  transfer atomicity, and rollback against PostgreSQL where behavior differs
  from SQLite.
- API: schemas, status/error bodies, pagination, idempotency, rate limits,
  authentication/token rotation, and a two-user authorization matrix.
- Migrations: empty-to-head and supported-version upgrade; downgrade only where
  product policy permits.
- Jobs: idempotency, duplicate dispatch, retry exhaustion, timeout, and metrics.

Unit tests may use SQLite only for logic that is not PostgreSQL-specific. Sync,
locking, uniqueness, JSON/index, and migration behavior run against PostgreSQL.

## Flutter

```powershell
Set-Location apps\money_pilot
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Cover domain/application units, Riverpod state, navigation/guards, Drift
migrations, outbox retry, widget validation, golden layouts at compact/medium/
expanded widths, desktop keyboard traversal, screen-reader semantics, text
scaling, reduced motion, high contrast, RTL, and offline/conflict/error states.
Goldens do not replace semantic assertions.

Platform integration tests run on at least Android plus Windows during private
beta; iOS/macOS require macOS CI or controlled release hardware. Linux smoke
tests run before declaring Linux support.

## End-to-end critical journeys

1. Register, verify, login, refresh, revoke another device, and reset password.
2. Complete or skip onboarding and reach a truthful dashboard.
3. Create accounts/categories; add/edit/split/refund/restore transactions.
4. Transfer atomically; reconcile an account; verify reports exclude transfers.
5. Make offline changes, restart, reconnect two devices, and resolve a conflict.
6. Record salary/bills/budget/goal and reproduce safe-to-spend explanation.
7. Import CSV with duplicate/invalid rows, undo batch, and export user data.
8. Ask AI with restricted account scope; approve exact draft; reject replay.
9. Reauthenticate, request deletion, cancel within policy, then complete deletion.

## Specialized suites

- **Financial:** negative/zero/large values, half-unit rounding, transfer/refund/
  split rules, overdue obligations, irregular income, missing rates, leap year,
  DST, month-end, and non-amortizing debt.
- **Sync chaos:** lost requests/acks, duplicates, reorder, crash during apply,
  stale tokens/versions, delete-update, schema skew, full resync, and two-device
  convergence.
- **Security:** IDOR, mass assignment, injection, token replay/races, enumeration,
  upload polyglots, signed URL expiry, export crossing, sensitive log snapshots.
- **AI:** untrusted receipt/import/merchant injection, unknown/recursive tools,
  selected-account scope, output schema failure, provider timeout, data
  exfiltration, proposal swap/expiry/replay/concurrency, and AI disabled.
- **Accessibility:** automated semantics plus keyboard/screen-reader manual passes;
  charts have equivalent summaries and status never relies on color.

## Test data

Factories generate random local-only users and deterministic scenario fixtures.
No production data is copied into tests. Contract vectors in
`packages/financial_contracts` are versioned and executed in every runtime that
implements calculations. Dates use fixed clocks and explicit time zones.

## CI gates

Python and Flutter workflows run on relevant changes. Before merging, format,
lint/analyze, tests, migration verification, secret scanning, and dependency
review must pass. Before release, add API/container scans, Android/desktop build
smokes, restore test evidence, and performance/security/accessibility reports.

## Manual smoke after a build

Launch the packaged artifact—not only debug mode—then verify startup, lock/unlock,
local database migration, add transaction, restart persistence, offline banner,
reconnect, privacy mode, keyboard navigation, export location, and clean exit.
Record platform, version, build hash, result, and evidence in the release record.
