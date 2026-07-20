# Security, privacy, and threat model

## Security claims

MoneyPilot uses TLS in transit, encryption at rest on server-managed storage, and
OS-backed protection for device secrets. This is **not true end-to-end
encryption** for synchronized records because the API must calculate, search,
and—with explicit consent—send minimized context to an AI provider. Do not market
it as E2EE. A local-only mode with cloud sync and AI disabled is the privacy
alternative.

## Assets and trust boundaries

Protected assets include credentials/tokens, financial records and attachments,
AI conversations/memories/tool traces, exports/backups, encryption/signing keys,
audit trails, and availability of the ledger. Trust boundaries exist between the
device and API, API and data stores, workers, object storage, email/push systems,
AI/exchange-rate providers, CI, and operators.

## Authentication and authorization

- The shipped local profile flow hashes passwords and one-time recovery codes
  with Argon2id, stores only salts/hashes, normalizes email addresses, returns
  generic invalid-credential errors, and temporarily locks a profile after five
  failed attempts. Financial snapshots use a profile-specific storage key.
- Passwords use Argon2id with reviewed parameters. Existing fallback algorithms
  are migration-only and rehash on successful login.
- Access tokens are short-lived. Refresh tokens are random, rotated on every use,
  hashed server-side, bound to a device/session family, and reuse revokes the
  family. Logout and account security pages support one/all-device revocation.
- Email verification/reset tokens are single-use, short-lived, rate-limited, and
  stored hashed. Responses resist account enumeration.
- Biometrics and PIN unlock a locally stored credential; the server never
  receives raw biometric data and has no generic `biometric-verify` endpoint.
- Every repository query is owner-scoped from authenticated context. APIs ignore
  or reject client-supplied ownership. Sensitive actions require recent login or
  a step-up challenge and produce a security event.
- Future household roles require an explicit workspace policy model and cannot
  reuse personal-owner assumptions.

## Threat model

| Threat | Primary controls | Verification |
|---|---|---|
| Credential stuffing/brute force | Argon2id, per-IP/account rate limits, generic responses, suspicious-login alerts | Auth abuse tests and alert drill |
| Token theft/replay | OS secure storage, TLS, rotation/reuse detection, short access TTL, device revocation | Refresh-race and replay tests |
| Cross-user record access/IDOR | Owner-scoped repositories, centralized policy, opaque errors | Two-user authorization suite |
| SQL/mass-assignment injection | Typed schemas, parameterized ORM, allowlisted mutable fields | Fuzz/static tests |
| Offline duplication/data loss | Stable operation IDs, revisions, tombstones, manual critical conflicts | Sync chaos tests |
| Malicious uploads | Size/type/magic-byte checks, sanitized names, private bucket, malware policy, isolated processors | Upload corpus tests |
| Export/data deletion abuse | Reauthentication, async audited job, short-lived signed link, rate limit | Cross-user and expiry tests |
| Prompt injection/data exfiltration | Untrusted-data boundaries, structured allowlisted tools, minimized context, server authorization | AI adversarial suite |
| AI unauthorized mutation | Draft-only tools, payload hash, single-use approval, optimistic concurrency | Proposal-swap/replay tests |
| Secret/supply-chain leak | Secret manager, protected environments, dependency/container scans, pinned release inputs | CI scanning and rotation drill |
| Sensitive telemetry/notifications | Redaction allowlist, generic lock-screen copy, diagnostics consent | Log/notification snapshot tests |
| Backup loss/exposure | Encryption, isolated credentials, retention, restore verification | Scheduled restore drill |

## Data protection

- Use managed database/storage encryption and KMS-backed keys in production;
  separate keys and accounts by environment. Rotate keys and credentials through
  a documented procedure.
- Flutter tokens use platform secure storage. Sensitive local database encryption
  requires a key protected by Keychain/Keystore/DPAPI-compatible facilities;
  lock timeout, balance hiding, app-switcher blur, and generic notifications are
  user controls.
- Secrets never enter source, images, logs, analytics, crash reports, or mobile
  build constants. `.env` is development-only.
- Never log passwords, complete tokens, account numbers, unredacted exports,
  receipt text, or full financial/AI payloads. Log stable IDs, outcome, timing,
  and redacted error classes.
- Signed object URLs are short-lived and purpose-limited. Original filenames are
  display metadata only, never storage paths.

## AI privacy

AI is disabled by default until configured. Users can disable AI, limit it to
summaries or selected accounts, inspect/delete memories and chat, and understand
which provider receives data. Send only tool results needed for the turn; avoid
raw transaction history when aggregates suffice. Provider retention/training
settings and processing region must be reviewed before production. Tool/audit
records contain redacted arguments when full values are unnecessary.

## Privacy lifecycle

Collect only required data and record purpose, retention, processor, and deletion
behavior in a data inventory before beta. The privacy center supports portable
export, chat/receipt deletion, diagnostics consent, session revocation, AI/sync
disablement, and account deletion with status. Backup retention and legal holds
are disclosed honestly; do not claim immediate deletion from immutable backups.

Legal compliance, tax treatment, and privacy policy require jurisdiction-specific
professional review. Engineering evidence supports review but is not a compliance
claim.

## Operational controls

- Separate local/development/staging/production accounts, networks, buckets,
  databases, keys, AI credentials, and telemetry projects.
- Least-privilege service identities; production access is time-bound, approved,
  MFA-protected, and audited.
- Dependency/SAST/container/secret scans run in CI. Critical findings block
  release; exceptions require owner, rationale, compensating control, and expiry.
- Incident runbooks cover credential exposure, cross-tenant access, malicious
  AI/tool behavior, backup failure, and lost signing keys. Preserve evidence,
  contain, rotate, assess notification duties, recover, and document follow-up.

## Security gates

Before public release: external threat-model review, penetration test, mobile and
desktop local-storage inspection, API authorization matrix, AI red-team cases,
backup restore, key rotation, dependency review, privacy/legal review, and proof
that production configuration rejects development secrets and permissive CORS.
