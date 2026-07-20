# Deliverable status

This matrix is the honest boundary of the 2026-07-15 MVP-foundation milestone.
"Implemented" means functional code and proportionate tests exist. "Designed"
means the engineering contract exists but the complete production path does not.

| # | Requested deliverable | Status | Evidence / boundary |
|---:|---|---|---|
| 1 | Product requirements | Implemented | `PRODUCT_SPEC.md` reconciles both source briefs and identifies non-goals. |
| 2 | User stories | Implemented | `USER_JOURNEYS.md` covers onboarding, daily use, AI approval, offline conflict, export, and deletion. |
| 3 | Acceptance criteria | Implemented | `MVP_BACKLOG.md` has phased stories and exit criteria. |
| 4 | System architecture | Implemented | `ARCHITECTURE.md` includes component, trust-boundary, and deployment diagrams. |
| 5 | Repository structure | Implemented | Monorepo plus `REPOSITORY_STRUCTURE.md`. |
| 6 | Database schema | Implemented | Typed SQLAlchemy models and initial Alembic revision; PostgreSQL production target and SQLite development fallback. |
| 7 | Entity-relationship diagram | Implemented | Mermaid ERD in `DATA_MODEL.md`. |
| 8 | API specification | Implemented | Versioned FastAPI routes, interactive docs, and committed `services/api/openapi.json`. |
| 9 | Flutter architecture | Implemented | Five native platform scaffolds, Riverpod state, GoRouter navigation, responsive shell, and documented target architecture. |
| 10 | Design system | Implemented | Light/dark/high-contrast themes, component rules, responsive breakpoints, and semantics guidance. |
| 11 | Wireframes / screen descriptions | Implemented | Screen map and state descriptions in `DESIGN_SYSTEM.md`; rendered previews under `docs/previews`. |
| 12 | Backend implementation | Implemented | Auth, owner-scoped core finance resources, dashboard, safe-to-spend, sync push, and guarded AI proposals. |
| 13 | Flutter implementation | Implemented foundation | Local registration/login/recovery, isolated empty workspaces, accounts, transactions, categories, budgets, bills, goals, dashboard, reports, purchase check, forecast, conversational coach, settings, and onboarding. Cloud API integration is deferred. |
| 14 | Local offline database | Prototype | Per-profile SharedPreferences JSON snapshots provide offline UX. Financial snapshots are not yet the planned encrypted Drift ledger/outbox. |
| 15 | Synchronization engine | Designed + server prototype | Idempotent/version-aware server push operations exist. Client outbox, pull cursor, conflicts, and API wiring are deferred. |
| 16 | AI provider abstraction | Implemented foundation | Provider-neutral service boundary with deterministic fallback; external providers remain configuration work. |
| 17 | AI coach | Implemented foundation | Private data-aware Local Coach supports multi-turn conversational prompts, honest missing-data responses, affordability explanations, and approval-required budget drafts. Server AI remains a separate optional path. |
| 18 | AI tool schemas | Implemented | Allowlisted structured read/simulate/propose tools and approval contract. |
| 19 | Financial calculation library | Implemented foundation | Integer-minor-unit dashboard, safe-to-spend, savings-rate, budget, allowance, and conversion helpers with shared vectors. Advanced formulas remain staged. |
| 20 | Background workers | Designed | Redis/object-storage topology and job responsibilities are documented; durable worker code is deferred. |
| 21 | Docker development environment | Implemented | Compose definition for API, PostgreSQL, Redis, MinIO, and Mailpit plus health checks. Docker was unavailable for live validation in this environment. |
| 22 | Database migrations | Implemented | Initial Alembic schema and clean migration-drift check. |
| 23 | Seed data | Development only | The optional API test endpoint retains development fixtures. The shipped Flutter client contains no financial seed dataset and every new profile starts empty. |
| 24 | Automated tests | Implemented foundation | Python and Flutter domain/API/widget/accessibility coverage; high-risk deferred-path tests are listed in the roadmap. |
| 25 | CI/CD | Implemented foundation | Python and Flutter GitHub Actions workflows; deployment promotion remains environment-specific. |
| 26 | Security checklist | Implemented | Threat model, controls, privacy design, and explicit prototype restrictions. |
| 27 | Deployment documentation | Implemented | Environment separation, migrations, rollback, backups, secrets, and observability guidance. |
| 28 | Store release checklist | Implemented | Platform signing, privacy, accessibility, QA, rollout, and rollback checklist. |
| 29 | Local account lifecycle | Implemented foundation | Create, sign in, sign out, recovery-code password reset, failure lockout, and account deletion with Argon2id-hashed secrets. |
| 30 | Screenshots / previews | Implemented | Desktop dashboard and mobile onboarding PNGs generated from Flutter widget tests and visually inspected. |

## Release boundary

This milestone includes a portable Windows desktop build for local use and
continued engineering. It is not a signed store release. Before regulated or
multi-device production use, complete the remaining P0 work. Before private
financial use, complete the P0 items in `ROADMAP_TECHNICAL_DEBT.md`, including
encrypted normalized storage, authenticated client/API integration, bidirectional
sync, durable audit semantics, and the full auth lifecycle.
