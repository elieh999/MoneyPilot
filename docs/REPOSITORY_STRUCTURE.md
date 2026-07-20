# Repository structure

```text
money_pilot_ai/
|-- .github/workflows/       # Python and Flutter quality gates
|-- apps/
|   `-- money_pilot/         # Flutter mobile/desktop client
|-- docs/                    # Product and engineering contracts
|-- infrastructure/
|   |-- api.Dockerfile       # API development/runtime image
|   `-- docker-compose.yml   # PostgreSQL, Redis, MinIO, Mailpit, API
|-- packages/
|   |-- financial_contracts/ # language-neutral vectors and schemas
|   `-- financial_core_python/
|       |-- src/             # deterministic server calculations
|       `-- tests/
|-- scripts/                 # PowerShell setup, run, and check helpers
|-- services/
|   `-- api/
|       |-- src/             # FastAPI routes, services, repositories, models
|       `-- tests/
|-- .env.example
|-- .gitignore
`-- README.md
```

## Dependency direction

- Flutter presentation depends on Flutter application/domain abstractions, not
  Dio, Drift, or platform plugins directly.
- API routes depend on application services; services depend on domain and
  repository interfaces; infrastructure implements those interfaces.
- Financial formulas live in the dedicated core and are never duplicated in
  API routes, UI widgets, background jobs, or AI prompts.
- Provider-specific AI adapters implement a provider-neutral interface. AI
  tools call the same authorized application services as REST routes.
- Language-neutral financial vectors are the contract between server and
  future Dart calculation implementations.

## Ownership conventions

- Server-generated owner IDs, audit fields, revisions, approval state, and
  authorization decisions are immutable from public request schemas.
- Generated Flutter files remain near the owning feature; generated code is not
  hand-edited.
- Migrations are append-only after sharing. Correct a migration with a new one.
- Architectural decisions that change an invariant require a short ADR under
  `docs/adr/` before implementation.
