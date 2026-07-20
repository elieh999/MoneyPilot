# MVP backlog and phase boundaries

Priority meanings: **P0** blocks the milestone, **P1** is required before a
private beta, and **P2** is intentionally deferred. A feature is complete only
when its happy path, permission checks, offline/error behavior, tests, and
documentation meet its acceptance criteria.

## Milestone 0 - runnable engineering baseline (P0)

- Monorepo, sample environment, local infrastructure, health endpoint, Flutter
  shell, deterministic financial core, CI, and no committed secrets.
- Acceptance: fresh Windows setup follows `docs/LOCAL_SETUP.md`; available Python
  and Flutter tests pass; API starts and OpenAPI loads; core containers become
  healthy; disabling AI does not prevent startup.

## Phase 1 - trustworthy ledger foundation (P0)

- Authentication lifecycle, sessions, security events, and local PIN/biometric
  unlock.
- Accounts, categories, transactions, split transactions, and atomic transfers.
- SQLite schema, outbox/inbox, sync push/pull, tombstones, idempotency, optimistic
  concurrency, conflict UI, and recovery states.
- Basic dashboard, search/filter, privacy mode, responsive navigation, and core
  accessibility.
- Acceptance:
  - Every API record is owner-authorized and cross-user access tests return no
    resource details.
  - Duplicate retries change state exactly once.
  - Offline create/edit/delete survives restart and converges after reconnect.
  - Transfers balance and never enter income/expense totals.
  - Financial values use integer minor units or fixed precision, never float.
  - Empty, loading, offline, conflict, and validation states are keyboard and
    screen-reader usable.

## Phase 2 - planning MVP (P0)

- Income sources and salary plan; budgets and periods; bills; savings goals;
  emergency reserve; safe-to-spend; basic reports; CSV import/export.
- Acceptance:
  - Formula examples and edge cases in `FINANCIAL_CALCULATIONS.md` have tests.
  - User-entered deductions are traceable; the product does not imply tax advice.
  - Each result exposes inputs, horizon, base currency, rounding, missing data,
    and whether it is estimated.
  - Import preview catches invalid rows/duplicates and confirmed import can be
    undone as one batch.
  - Bill and goal edits made offline follow the documented conflict rules.

## Phase 3 - constrained intelligence (P1)

- Provider-neutral AI adapter, streaming chat, authorized tools, context
  minimization, action proposals, approval screen, AI privacy/memory controls,
  and deterministic insight explanations.
- Acceptance:
  - The application works with AI disabled and with the deterministic mock.
  - Provider contract tests cover timeout, malformed output, rate limit, and
    refusal paths.
  - Tool schemas reject unknown fields; tool calls reauthorize ownership.
  - No model-generated SQL/shell is executed.
  - Every write requires an unexpired single-use approval bound to user, action,
    resource version, and payload hash.
  - Imported text cannot enter system instructions; prompt-injection tests pass.

## Phase 4 - advanced personal finance (P1)

- Debts and payoff simulations, subscriptions and recurring detection, receipt
  scanning, net worth, multi-currency, forecasts, encrypted backups, and richer
  reports.
- Acceptance: historical currency rates are retained; debt projections disclose
  assumptions; OCR is review-only; backups are restore-tested; forecast ranges
  are labeled uncertain.

## Phase 5 - production readiness (P0 before public release)

- Security hardening, retention/deletion jobs, accessibility audit, localization,
  observability, performance/load work, signed releases, backup/restore drills,
  penetration test remediation, privacy/terms review, and incident runbooks.
- Acceptance: all items in `RELEASE_CHECKLIST.md` have owner/evidence; staging
  rollback and restore drills succeed; no critical/high unresolved finding is
  accepted without written risk ownership.

## Post-MVP (P2)

Bank aggregation, household spaces, advisor/business modes, real money movement,
market-rate bill comparison, automated cancellation, smartwatch apps, yearly
animated recap, advanced habit gamification, and public store distribution are
separate initiatives. Their interfaces must not weaken current tenant isolation
or ledger invariants.
