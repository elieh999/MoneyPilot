# Offline synchronization protocol

## Goals and boundary

Core records can be created, read, edited, and deleted without a network. Sync
must be retry-safe, converge across devices, expose conflicts, and never silently
discard financial data. AI, cloud OCR, email, live exchange rates, and
cross-device delivery are server-only and show queued/unavailable states offline.

Realtime messages are only hints to pull. The ordered server revision stream is
the source of synchronization correctness.

## Client state

Each installation has a random device ID and SQLite tables for domain rows,
outbox operations, applied remote operations, sync cursor, conflicts, and schema
metadata. A local user action commits the domain change and outbox row in one
SQLite transaction before the UI reports success.

An operation contains:

```text
operation_id       UUID generated once and retained across retries
device_id          registered installation
entity_type/id     stable UUID, including offline-created records
kind               create | update | delete | resolve
base_version       server version observed before local edit; 0 for create
patch              schema-validated fields or tombstone intent
schema_version     payload contract version
dependencies       operation IDs that must succeed first
client_created_at  diagnostic ordering only; never conflict authority
```

## Push

1. Client sends dependency-ordered batches with an access token and batch
   idempotency key.
2. Server authenticates, replaces owner with the authenticated user, validates
   the schema, authorizes resource/dependencies, and checks `operation_id`.
3. An already processed operation returns its original result.
4. Compatible operation applies in one transaction with audit entry and a new
   per-user monotonically increasing `server_revision`.
5. Response is per operation: `applied`, `already_applied`, `rejected`,
   `blocked_by_dependency`, or `conflict`.
6. Client removes only acknowledged operations. Validation/authorization failures
   stop automatic retry and show a recoverable local error.

Linked transfer legs and multi-row splits are one aggregate operation. They
cannot partially apply.

## Pull

`GET /api/v1/sync/pull?after=<opaque_cursor>&limit=...` returns records and
tombstones ordered by server revision plus `next_cursor` and `has_more`. The
client applies the full page and advances its cursor in one local transaction.
Crash before commit repeats the same page safely. Pull continues until caught up.

The server retains tombstones beyond the maximum supported inactive-device
window. A device older than that window performs an explicit full resync rather
than resurrecting deleted data.

## Conflict rules

Server receive order, not device clocks, orders operations. `base_version` equal
to current version is a normal update. Otherwise:

| Data | Policy |
|---|---|
| Additive audit/security history | Append; never overwrite. |
| Different noncritical fields | Three-way merge when the common base proves fields are disjoint. |
| Tags | Membership add/remove operations merge by tag ID; a later explicit removal wins only for that membership. |
| Local display preferences | Latest server revision may win, with prior value retained in audit where relevant. |
| Amount, currency, account, type, date, splits, transfer legs, status | Manual conflict; no automatic overwrite. |
| Budget limit/period, bill amount/due date, goal target, salary assumptions | Manual conflict because derived advice changes. |
| Delete versus update | Keep tombstone pending user review; destructive server confirmation required. |
| Same-field concurrent edit | Manual conflict even when values appear similar. |

Conflict UI shows common base, local value, server value, affected calculations,
and choices to keep local, keep server, or create a validated merged revision.
Resolution is a new `resolve` operation referencing both versions; history stays
auditable.

## Dependencies and referential integrity

- Offline UUIDs are final; the server does not replace IDs.
- Account/category creates precede transactions that reference them.
- A parent rejection blocks dependents rather than dropping references.
- Category deletion with referenced transactions archives or remaps through an
  explicit action; it never nulls financial history silently.
- Client schema migration runs before sync. Unsupported protocol versions return
  a required-upgrade response without mutating data.

## Retry and connectivity

Retry network/5xx/429 failures with jittered exponential backoff, capped at five
minutes while foregrounded and OS-appropriate scheduling in background. Honor
`Retry-After`. Authentication refresh is serialized per device. Manual sync may
trigger an immediate attempt but does not create duplicate workers.

## Status and recovery

The UI exposes last successful sync, pending count, blocked count, conflicts,
current connectivity, and a manual retry. Pending data remains fully visible.
Logout offers to finish sync or explicitly retain/discard the encrypted local
profile. Reinstall/recovery restores server-synchronized data but cannot promise
recovery of never-synced local operations.

## Test matrix

Cover duplicate push, lost acknowledgement, reordered batches, crash during local
apply, stale token, dependency failure, same/different-field edits, delete/update,
transfer atomicity, tombstone expiry/full resync, pagination boundaries, two
devices reconnecting simultaneously, and server/client schema skew.
