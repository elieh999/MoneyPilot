# Data model and entity relationship diagram

## Conventions

Financial entities use UUIDs, authenticated `owner_id`, UTC `created_at` and
`updated_at`, `deleted_at` tombstones where appropriate, monotonic `version`, and
`source`. Money stores integer minor units plus ISO 4217 currency. Flexible JSON
is limited to provider metadata or versioned snapshots; searchable domain data
is normalized.

Public schemas never accept authoritative owner, audit, approval, or revision
fields. Foreign keys and service policies preserve financial history. A user
deletion workflow, rather than informal cascades, controls erasure.

## Entity groups

- **Identity/security:** users, profiles, preferences, identities, sessions,
  devices, security events, recovery codes.
- **Ledger:** accounts, balance snapshots, reconciliations, transactions,
  transfer groups, transaction splits, attachments, merchants, categories,
  rules, tags, transaction tags.
- **Planning:** income sources, salary plans/deductions/allocations, budgets,
  periods and category lines, bills and occurrences, goals and contributions,
  emergency fund configuration.
- **Advanced finance:** subscriptions and price history, debts and payments,
  assets, net worth snapshots, forecast scenarios and points, exchange rates.
- **Operations:** sync operations, server revisions for each user, audit logs,
  notifications/preferences, imports/rows, exports, receipts/items, user files.
- **AI:** conversations, messages, tool calls, action proposals/approvals,
  memories, insights, evidence, and feedback.

## Current data map

```mermaid
erDiagram
    USER ||--|| USER_PROFILE : has
    USER ||--o{ SESSION : authenticates
    USER ||--o{ DEVICE : owns
    USER ||--o{ ACCOUNT : owns
    USER ||--o{ CATEGORY : owns
    USER ||--o{ TRANSACTION : owns
    USER ||--o{ BUDGET : owns
    USER ||--o{ INCOME_SOURCE : owns
    USER ||--o{ BILL : owns
    USER ||--o{ SAVINGS_GOAL : owns
    USER ||--o{ SYNC_OPERATION : submits
    USER ||--o{ AUDIT_LOG : produces

    ACCOUNT ||--o{ TRANSACTION : records
    TRANSACTION ||--o{ TRANSACTION_SPLIT : contains
    CATEGORY ||--o{ TRANSACTION_SPLIT : classifies
    CATEGORY ||--o{ CATEGORY : parent_of
    TRANSACTION }o--o| TRANSFER_GROUP : links

    BUDGET ||--|{ BUDGET_PERIOD : spans
    BUDGET_PERIOD ||--o{ BUDGET_LINE : allocates
    CATEGORY ||--o{ BUDGET_LINE : limits

    INCOME_SOURCE ||--o{ INCOME_OCCURRENCE : schedules
    BILL ||--o{ BILL_OCCURRENCE : schedules
    SAVINGS_GOAL ||--o{ GOAL_CONTRIBUTION : receives
    ACCOUNT ||--o{ GOAL_CONTRIBUTION : funds

    USER {
      uuid id PK
      text email UK
      text password_hash
      timestamptz created_at
      timestamptz deleted_at
    }
    ACCOUNT {
      uuid id PK
      uuid owner_id FK
      text type
      text currency
      bigint opening_balance_minor
      boolean include_safe_to_spend
      int version
      timestamptz deleted_at
    }
    TRANSACTION {
      uuid id PK
      uuid owner_id FK
      uuid account_id FK
      uuid transfer_group_id FK
      text kind
      bigint amount_minor
      text currency
      timestamptz occurred_at
      text status
      int version
      timestamptz deleted_at
    }
    TRANSACTION_SPLIT {
      uuid id PK
      uuid transaction_id FK
      uuid category_id FK
      bigint amount_minor
      text currency
    }
    SYNC_OPERATION {
      uuid operation_id PK
      uuid owner_id FK
      text device_id
      text entity_type
      uuid entity_id
      int base_version
      text outcome
      bigint server_revision
    }
```

## Ledger decisions

- Amounts are zero or greater; transaction `kind` determines direction.
  This avoids ambiguous APIs with mixed signs. Refunds reduce the original expense
  category when linked; otherwise they are reported as unallocated refunds, not
  salary/income.
- A transfer is two linked account legs sharing `transfer_group_id`, written in
  one transaction. Transfers between currencies retain source amount, destination
  amount, currencies, and applied rate.
- Account balance is derived from opening balance plus posted ledger entries.
  Cached/snapshot balances include an `as_of_revision`; reconciliation creates
  an explicit adjustment rather than rewriting history.
- Split totals must equal the parent amount in the same currency. Rounding
  remainder is assigned consistently to the last visible split.
- Pending entries affect available balance policy but not finalized reports.

## Constraints and indexes

- Unique normalized email; unique `(owner_id, device_id, refresh_token_family)`;
  unique `(owner_id, operation_id)` and import row fingerprint per import.
- Checks for valid currency and scale, amounts of zero or greater, valid date ranges,
  supported entity states, and exactly two balanced transfer legs.
- Owner and date indexes on transactions; owner, status, and due date indexes on bills;
  owner/deleted/version indexes for sync; expiry indexes on sessions, proposals,
  exports, and upload reservations.
- Partial indexes should exclude tombstoned rows for ordinary queries while
  preserving tombstones until all active device retention windows pass.

## Possible household support

Future sharing introduces `workspace`, `workspace_member`, and scoped roles.
Until that migration exists, `owner_id` is always the authenticated user. Do not
simulate sharing by accepting another user's ID or weakening repository filters.
