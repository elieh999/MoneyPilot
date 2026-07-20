# Product specification

## Product promise

MoneyPilot AI gives an individual a calm, transparent answer to four questions:
what they have, where it went, what is already committed, and what is safe to
spend. It works offline for core financial records and synchronizes across the
user's devices when connected. AI is an optional explanation and planning
layer, not the system of record.

The name is configurable through `APP_NAME`; **MoneyPilot AI** is authoritative
for this repository. AI integration is provider-neutral. No business logic may
depend directly on a vendor SDK.

## Intended users and platforms

The initial user is one person managing personal finances. The schema reserves
an ownership boundary for later household sharing, but shared finance and
advisor/business workflows are outside MVP.

- Flutter: Android, iOS, Windows, macOS, and Linux where Flutter supports the
  required plugins.
- FastAPI: versioned REST API and streaming channel.
- SQLite/Drift: local-first client store.
- PostgreSQL: synchronized server record.

## MVP outcomes

A user can register, complete minimal onboarding, create accounts and
categories, record income/expenses/transfers, work offline, synchronize without
duplication, plan salary and budgets, track bills/goals, and inspect a
transparent safe-to-spend result. The user can ask an optional AI coach to
explain authorized data; any proposed write is separately reviewed and approved.

## Functional requirements

### Foundation

- Email/password registration, verification, login, refresh-token rotation,
  current/all-device logout, password reset, local PIN/biometric unlock, and
  session/security-event views.
- Account, category, tag, and transaction CRUD with search, filters, split
  transactions, transfers, soft deletion, undo, and duplicate warnings.
- Accessible responsive shell, privacy mode, light/dark/system themes, empty,
  error, loading, offline, and sync states.
- Local mutation queue, pull cursor, idempotent API writes, conflict review, and
  no silent data loss.

### Planning

- Income sources, salary plan, user-entered deductions, stable/irregular income
  baseline, budgets, bills, savings goals, emergency fund, reports, and
  safe-to-spend explanation.
- CSV import with preview, mapping, per-row errors, duplicate detection, and
  rollback; CSV/PDF/user-data export.
- Recurring rules and reminders. Detection may suggest a recurring item but
  never activates it without review.

### Intelligence

- Provider-neutral AI chat with streaming, structured read tools, minimized
  context, citations to internal facts, and explicit uncertainty.
- Draft-only action proposals with a short-lived approval token.
- Proactive insights are deterministic/rule-based first; AI may explain a
  verified insight but must not invent its numeric evidence.
- Natural-language quick entry and OCR always display parsed fields before save.

## Explicitly deferred beyond MVP

Bank aggregation, automatic money movement, investment execution/advice,
smartwatch apps, household sharing, marketplace bill pricing, automated
subscription cancellation, advanced tax calculations, long-horizon machine
learning, and store publication are later phases. Interfaces may be reserved,
but placeholders must not be represented as working features.

## Product rules

- No financial shaming, gambling/trading aesthetics, guaranteed outcomes, or
  hidden calculation inputs.
- Core offline functionality excludes server-only AI, email, cloud OCR, exchange
  rate refresh, and cross-device sync; those features clearly show unavailable
  or queued states while offline.
- Gross-to-net salary is not a tax engine. MVP subtracts user-entered deductions.
- Multi-currency totals use stored historical rates. Missing rates yield an
  incomplete/estimated result instead of silently assuming parity.
- Transfers use linked debit/credit legs in one atomic operation and are
  excluded from income/expense totals.

## Success measures

- Transaction entry can be completed in two primary actions after defaults are
  established.
- A retried mutation creates no duplicate financial record.
- Every safe-to-spend value has a reproducible explanation.
- Every personalized AI recommendation exposes relevant numbers, assumptions,
  confidence, and alternatives.
- Critical financial calculation and sync-conflict cases have deterministic
  automated tests.
- Accessibility checks cover keyboard navigation, screen-reader labels, text
  scaling, non-color status, reduced motion, and chart summaries.

## Nonfunctional targets

- API p95 below 400 ms for ordinary paginated CRUD under the agreed staging
  load; long jobs are asynchronous.
- First meaningful local dashboard render below 2 seconds on supported baseline
  hardware after the local database is opened.
- UTC server timestamps and IANA user time zones; calendar calculations use the
  user's local zone.
- Least-privilege services, redacted structured logs, health/readiness probes,
  verified backups, dependency scanning, and staged rollout/rollback.
- English ships first; strings, layouts, number/date/currency formatting, and
  AI language selection are localization-ready, including RTL.

## Open product decisions

Before public beta, product owners must select supported OS minimums, initial
countries/currencies, notification providers, data-retention periods, AI
providers/regions, backup RPO/RTO, legal documents, subscription model, and
support process.
