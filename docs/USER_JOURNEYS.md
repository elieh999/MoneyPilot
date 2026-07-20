# Primary user journeys

## 1. First useful dashboard

1. User registers, verifies email, and chooses local PIN/biometric unlock.
2. Onboarding explains why each optional answer is requested.
3. User selects region, currency, income cadence, one account balance, and
   essential bills; skipped questions remain editable.
4. The app proposes, but does not silently save, a starter budget, emergency
   target, and salary-day allocations.
5. Dashboard displays available balance, next payday, committed bills,
   safe-to-spend, and the inputs behind each derived number.

Acceptance: an entirely skipped onboarding still opens a useful empty dashboard;
partial data produces an explicitly incomplete estimate rather than a false zero.

## 2. Add an expense offline and synchronize

1. User taps quick add, enters amount/account/category/merchant, and saves.
2. SQLite commits the transaction and an outbox operation atomically.
3. Dashboard updates immediately and displays a pending-sync indicator.
4. Connectivity resumes; the client sends the stable operation ID and base
   revision, then advances its pull cursor.
5. The server applies the operation once; all devices receive the new revision.

Acceptance: killing/restarting the app or retrying the request cannot lose or
duplicate the transaction.

## 3. Transfer between accounts

1. User selects source, destination, amount, date, and optional exchange rate.
2. The preview shows both linked ledger legs and any conversion difference.
3. One atomic save records both legs under one transfer ID.
4. Reports exclude both legs from income and expense while account balances
   reflect them.

Acceptance: the operation cannot leave only one transfer leg committed.

## 4. Plan salary and safe-to-spend

1. User records net income or gross income plus explicit deductions and cadence.
2. User confirms bills, minimum debt payments, planned savings, reserve, and
   accounts included in spending availability.
3. The engine computes conservative income before the horizon and committed
   obligations.
4. The result shows raw surplus/shortfall, non-negative spendable amount, daily
   and weekly allowances, assumptions, missing data, and forecast confidence.
5. User can change one assumption and compare the result before saving.

## 5. Import a statement

1. User selects a CSV and maps columns; raw file content is treated as untrusted.
2. Preview normalizes dates/currencies, shows row errors, and flags duplicates.
3. User confirms accepted rows. The import uses stable row fingerprints and an
   idempotency key.
4. Imported transactions are marked `unreviewed`; a summary supports undo.

Acceptance: a partial failure identifies every rejected row and never silently
imports it with guessed values.

## 6. Ask the AI coach and approve an action

1. User asks whether a purchase is affordable.
2. The orchestrator selects allowlisted read/simulation tools and obtains only
   the required, owner-authorized summaries.
3. The response presents evidence, formula, assumptions, confidence, downside,
   alternative, and educational-not-advice label.
4. If the user asks to change a budget, AI creates a draft with an exact diff.
5. A native confirmation screen re-authenticates when risk requires it. The API
   validates an unexpired single-use approval token and applies the exact diff.

Acceptance: chat text such as "yes" alone cannot authorize a mutation, and an
approved draft cannot be swapped for different parameters.

## 7. Resolve a sync conflict

1. Device edits a critical amount from an outdated base revision.
2. Server returns the current record plus conflict metadata without overwriting.
3. Client shows local, server, and common-base values and explains downstream
   calculations affected.
4. User keeps one version or creates a deliberate merged edit.
5. Resolution is a new auditable operation; neither prior value disappears.

## 8. Export and delete data

1. User reauthenticates and requests a portable archive.
2. Background job creates a time-limited encrypted artifact and notifies the
   user generically.
3. Account deletion shows consequences, cooling-off policy, and status.
4. Primary data is deleted or cryptographically erased according to policy;
   backup expiry is disclosed and tracked.

Acceptance: exports never cross tenants, links expire, security events are
retained only as allowed by policy, and the UI does not claim immediate backup
erasure when retention still applies.
