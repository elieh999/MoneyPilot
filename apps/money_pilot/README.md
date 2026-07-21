# MoneyPilot Flutter client

This directory contains the Flutter application for desktop and mobile.

New profiles start with no financial records. Local authentication supports
password hashing, recovery codes, sign in lockout, sign out, and account
deletion. Each profile has a separate locally stored workspace.

The interface includes accounts, transactions, budgets, bills, goals, reports,
purchase checks, calendar summaries, appearance settings, and a local financial
coach. English, French, and Arabic are built in. Arabic switches the layout to
right to left and uses the bundled Noto Sans Arabic font.

Run the client checks from this directory:

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

The client stores an AES-GCM encrypted financial snapshot through
`shared_preferences`, supports validated CSV transfer and recurring activity
insights, and can verify an optional FastAPI account session. It does not send
financial records to the service. See
[`docs/ROADMAP.md`](../../docs/ROADMAP.md) for the planned integration work.
