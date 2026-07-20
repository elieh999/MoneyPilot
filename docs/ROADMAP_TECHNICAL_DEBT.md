# Roadmap and technical debt

This is a living gap register, not a claim that the full product brief is already
implemented. Snapshot: initial runnable scaffold, 2026-07-15. Reassess after each
milestone and attach issue IDs/owners before collaborative development.

## Current foundation

- FastAPI scaffold with versioned routes, Argon2id, rotated hashed refresh-token
  identifiers, owner-scoped core records, accounts/categories/transactions,
  planning/dashboard endpoints, integer-minor-unit calculations, a sync-operation
  push prototype, an initial Alembic migration, and a deterministic
  provider-neutral AI boundary.
- Python financial contract vectors and API/core test suites.
- Flutter multi-platform scaffold and product prototype with Riverpod/GoRouter,
  responsive screens, local prototype persistence, and sample financial flows.
- Local PostgreSQL/Redis/MinIO/Mailpit/API Compose definition, CI, and engineering
  contracts in this documentation set.

The word "prototype" matters: the items below prevent treating this scaffold as
production-ready.

## P0 debt before shared/private financial use

| Gap | Risk / target resolution |
|---|---|
| Flutter stores an aggregate JSON prototype rather than a versioned Drift ledger/outbox | Crash consistency, scale, migration, and sync are insufficient. Introduce normalized Drift tables, atomic domain+outbox writes, encrypted local storage, migration tests, and repository interfaces. |
| Flutter/API contracts and authentication are not fully integrated | Replace demo-only client state with Dio API client, secure token storage/refresh serialization, offline repository, API error mapping, and sign-in/session UI. |
| Client signed-amount model differs from server magnitude+type policy | Adopt shared versioned schemas/contract fixtures before syncing; write migration for existing prototype state. |
| Server still calls metadata `create_all` at startup even though an initial Alembic revision exists | Review the baseline, add migration CI, remove production auto-create, and test supported upgrades plus SQLite-development/PostgreSQL parity where relevant. |
| Sync prototype provides push only, with no ordered pull cursor/global revision/dependencies/three-way conflict detail | Implement `OFFLINE_SYNC.md`, tombstone retention/full resync, transfer aggregate semantics, and two-device chaos tests. |
| The server checks proposal ownership, expiry, canonical payload hash, one-time status, and tampering, but the offline Flutter coach does not share that contract | Move the client to server-issued proposal DTOs, validate versions and exact diffs, and add client/server expiry, replay, and tamper integration tests before enabling remote AI writes. |
| Ordinary REST writes do not yet have a general idempotency-key store | Add owner/route/key/request-hash/result records with expiry; reject key reuse for different payloads. |
| Auth lifecycle is partial | Add email verification/reset, current/all-device logout UI, session/device view, rate limiting, lockout/recovery, security events/alerts, and concurrency tests. |
| No durable audit/security event model for material changes | Add redacted append-only events tied to correlation/user/device/operation and retention policy. |
| Flutter coverage proves calculations, money parsing, core balance changes, approval/rejection, onboarding, responsive navigation, and semantics, but not persistence/sync failure modes | Add delayed-hydration, reversed-write, corrupt-schema recovery, API contract, conflict, keyboard, and stable golden coverage. |
| Whole-snapshot local writes and startup hydration are asynchronous and not serialized | Load before editing, queue or transact writes, expose durable save/error state, preserve corrupt payloads for recovery, and test adversarial completion ordering. |
| The local ledger allows direct balance replacement and destructive account/transaction deletion | Use reconciliation entries, archive accounts, keep tombstones and undo windows, and align the client audit model with the API. |
| Safe-to-spend demo assumptions use fixed savings/buffer values and name-based emergency-fund detection | Store explicit user allocations, enforce one budget per category/period, and expose every assumption in editable settings. |

## P1 debt before private beta

- Normalize account balance snapshots and reconciliation; ensure every transfer is
  represented as linked balanced legs rather than only balance mutations.
- Add pagination/filter/sort and consistent error codes across list APIs; enforce
  `If-Match`/version behavior and ownership at repository boundaries.
- Expand financial core from the current dashboard/safe-to-spend/budget helpers
  to salary cadence, goals, emergency coverage, bills, reports, and rounding/date
  edge cases. Label zero-income savings rate as unavailable in API/UI even if the
  low-level helper returns zero for backward compatibility.
- The current currency conversion helper multiplies minor units directly and is
  valid only when source/target minor-unit scales match. Phase 4 multi-currency
  must implement the scale-aware normative formula and historical rates; this is
  not a blocker for the explicitly single-currency MVP.
- Add import preview/fingerprint/undo and export jobs with private object storage;
  integrate Redis and a durable worker rather than treating it as authoritative.
- Add secure local lock/biometric implementation, app-switcher privacy, generic
  notifications, diagnostics consent, and data export/deletion lifecycle.
- Add structured redacted logging, correlation propagation, metrics/tracing,
  error monitoring, readiness dependency policy, and operator runbooks.
- Resolve product decisions for supported OS versions, beta countries/currency,
  retention, AI providers/regions, notification/email services, and support.

## Phase roadmap

### A. Close foundation gaps

Contract-first Flutter/API integration, Drift/outbox, complete auth lifecycle,
Alembic baseline, server pull stream, conflicts, idempotency, audit events, and
critical end-to-end tests. Exit criteria are Phase 1 in `MVP_BACKLOG.md`.

### B. Planning MVP

Income/salary/deductions, budgets, bills, goals/emergency reserve,
safe-to-spend explanation, dashboard reports, CSV import/export, and local/server
parity. Keep one base currency and user-entered deductions to constrain risk.

### C. Constrained AI

Provider adapter and streaming, consent/scoping, allowlisted read/simulate tools,
evidence contract, proposal approval hardening, memory/privacy controls, and AI
red-team suite. AI remains feature-flagged and disabled without configuration.

### D. Advanced finance

Debts, subscriptions, recurring detection, OCR, historical multi-currency, net
worth, forecasts/scenarios, notification jobs, encrypted export/backup restore.

### E. Production and distribution

Accessibility/localization audit, performance/load, production IaC, SLO/on-call,
restore/incident drills, external security/legal review, signing/notarization,
package/store assets, and staged rollout.

## Explicit non-goals until separately approved

Bank credential handling, initiating payments or investments, tax computation,
automatic subscription cancellation, household sharing, advisor/business
accounting, smartwatch clients, and claims of guaranteed savings or legal
compliance. Architecture may remain extensible, but dormant menu items are not a
substitute for implemented and tested features.

## Debt management rule

Every accepted item records severity, owner, target milestone, user/data impact,
mitigation, and validation evidence. P0 items may not be silently converted to
"later" because a demo works. Conversely, advanced Phase 4/5 items should not
delay testing the core ledger and planning formulas.
