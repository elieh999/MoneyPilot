# MoneyPilot AI 1.1.0

## Ready-to-run experience

- The Windows build opens by double-clicking `MoneyPilot AI.exe` or the root
  `MoneyPilot AI` shortcut.
- New profiles start completely empty: no sample balances, salary, expenses,
  bills, goals, budgets, or messages.
- Create and sign into multiple local profiles. Each financial workspace is
  stored separately.
- Passwords and recovery codes are Argon2id-hashed. Registration shows a
  one-time recovery code; five failed sign-in attempts trigger a short lockout.
- Sign out, recover a forgotten password, clear financial data, or permanently
  delete a local profile from Settings.

## AI and planning

- The private Local Coach now handles greetings and follow-up questions, explains
  safe-to-spend, balances, spending, income, bills, goals, and purchase
  affordability from the user's real records.
- Missing information produces an explicit request for data instead of a made-up
  answer.
- Budget suggestions become typed proposals. Nothing changes until the exact
  proposal is approved; rejection leaves data untouched.
- New Purchase Check compares a proposed price with safe-to-spend, shows the
  post-purchase buffer, adds a cooling-off date, and can continue the decision in
  the Coach.
- Coaching style and a personal safety buffer are configurable in Settings.

## Verified

- Flutter static analysis: no issues.
- Flutter tests: 22 passed.
- Python API and financial-core tests: 34 passed.
- Python lint and formatting: passed.
- Final packaged executable: release launch smoke tested on Windows.

The app is an educational planning tool, not financial, tax, investment, or
legal advice. Local financial snapshots are profile-isolated but are not yet
database-level encrypted; protect the Windows user account and device.
