# Deployment and operations guide

## Environment model

Use isolated local, development, staging, and production environments with
separate cloud accounts/projects where practical. Never share databases,
buckets, Redis, signing keys, AI credentials, email domains, telemetry, or JWT
secrets across staging and production.

The local Compose stack is not a production topology. Production uses a
stateless API, separately scaled workers/scheduler, managed PostgreSQL with point-
in-time recovery, managed Redis, private S3-compatible storage, secret manager,
TLS ingress/WAF, restricted egress, monitoring, and immutable image registry.

## Configuration and secrets

Configuration is environment-driven. Secrets come from the deployment secret
manager at runtime, never baked into images or Flutter assets. Required
production settings include a unique strong token-signing secret or managed key,
database/Redis credentials, object-storage keys, email/push credentials, AI
provider configuration when enabled, allowed origins/deep links, telemetry DSN,
retention, and backup policy.

Startup must reject the development JWT/MinIO passwords, wildcard production
CORS, debug mode, insecure URLs, and missing required encryption keys.

## API image

From repository root:

```powershell
docker build -f infrastructure\api.Dockerfile -t registry.example/money-pilot-api:VERSION .
docker run --rm registry.example/money-pilot-api:VERSION python -m pytest --help
```

CI should build once, scan/sign the immutable image, promote the same digest, and
generate an SBOM. Do not rebuild separately per environment.

## Release sequence

1. Pass tests, scans, migration rehearsal, and release checklist in staging.
2. Take/verify a recoverable backup and record current application/schema/image
   versions.
3. Run backward-compatible Alembic migrations as a single controlled job.
4. Deploy API/workers with readiness disabled until dependencies/migrations are
   compatible; use canary or rolling rollout.
5. Exercise health, auth, account/transaction, sync, file, and AI-disabled smokes.
6. Enable traffic gradually and monitor error rate, p95 latency, database locks,
   job backlog/failures, sync conflicts, AI cost/failures, and security events.
7. Record evidence and notify owners. Remove compatibility code only after the
   supported client migration window.

Schema changes use expand/migrate/contract. A mobile client may remain installed
for months, so API and sync protocol compatibility cannot assume instant upgrade.

## Health and observability

- Liveness means the process loop responds; readiness verifies required database
  access and migration compatibility without depending on optional AI/email.
- Structured logs carry correlation/request/job/operation IDs and redact
  financial content.
- Alert on sustained availability/latency, authentication abuse, cross-tenant
  policy failures, sync rejection spikes, database capacity/replication lag,
  backup failure, dead-letter jobs, object-storage errors, and unexpected AI cost.
- Define SLOs and on-call ownership before public beta; the product brief's local
  performance targets are not production SLOs by themselves.

## Backup and restore

- PostgreSQL: encrypted automated backups plus point-in-time logs in another
  failure domain; retention follows approved policy.
- Object storage: versioning where appropriate, lifecycle policy, and inventory
  reconciliation with database metadata.
- Secrets/config: secure recoverability and tested rotation, not copied into data
  backups.
- Redis is not authoritative financial storage.

A scheduled restore drill creates an isolated environment, restores database and
objects, verifies checksums/migration state and representative records, and
records measured RPO/RTO. Never report backup success solely because a job ran.

## Rollback

Prefer rolling back application traffic to the prior signed image while keeping
forward-compatible schema. Destructive migration rollback requires a rehearsed
data plan and explicit owner approval. If integrity is uncertain, enter read-only
maintenance, preserve evidence, and recover deliberately rather than applying
ad-hoc edits.

## Flutter distribution

Build release artifacts only on supported trusted runners:

```powershell
flutter build appbundle --release
flutter build windows --release
flutter build linux --release
```

iOS/macOS require macOS and Apple signing/notarization. Windows and Linux package
formats, update channels, store metadata, icons, permissions, privacy manifests,
crash symbols, and code signing are platform release work. API base URLs and
public non-secret identifiers may be compile-time environment configuration;
provider secrets never ship in the client.

## Infrastructure gap

Production infrastructure-as-code and a worker image are intentionally not
invented before a hosting provider, region/data residency, RPO/RTO, and scaling
model are selected. Record those decisions and add reviewed IaC before staging.
