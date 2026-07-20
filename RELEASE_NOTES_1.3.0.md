# MoneyPilot 1.3.0

Release date: July 20, 2026

## Highlights

- Completed English, French, and Arabic localization across screens, cards,
  dialogs, validation messages, settings, navigation, safety controls, and
  dynamic status text.
- Added an on-screen language selector to the sign-in and account-creation
  experience. Arabic automatically uses right-to-left layout.
- Added a spending calendar with daily income, daily expenses, transactions,
  no-spend days, monthly totals, and the highest-spending day.
- Added Ocean, Cyan, Forest, Violet, and Sunset color palettes.
- Added optional accent glow effects that work with light, dark, and system
  appearance modes.
- Strengthened local-data safety. Financial data deletion now requires the
  explicit confirmation word `WIPE`, while account deletion continues to
  require the account password.
- Financial-data wiping preserves the user's language, appearance, privacy
  preferences, login, and category definitions.
- Expanded the Local Coach regression suite across affordability,
  safe-to-spend, spending, bills, goals, income, and budget proposals in all
  three languages.

## Reliability

- Corrected a dialog controller lifecycle issue discovered during destructive
  data-control testing.
- Corrected narrow mobile calendar overflow in Arabic by introducing compact
  income and expense indicators.
- Added tests for translation parity, palette persistence, glow styling,
  calendar calculations, mobile Arabic rendering, and secure data wiping.
- The Windows executable and delivery ZIP are smoke-tested after packaging.

## Privacy

- New accounts remain empty; no fabricated transactions or balances are added.
- Financial records remain isolated by local account.
- The Local Coach reads only the current local profile and never moves money.
- No `.env`, local profile data, caches, or test logs are included in the
  release archive.
