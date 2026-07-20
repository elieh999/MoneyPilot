# MoneyPilot AI Flutter client

The responsive client runs on mobile, desktop, and web. Every new local profile
starts with an empty financial workspace. Local authentication includes Argon2id
password hashing, recovery-code reset, failure lockout, logout, and account
deletion. Records are isolated by profile.

The private Local Coach works offline and answers conversational questions from
the accounts, transactions, bills, budgets, and goals the user has entered. It
does not invent missing balances. Budget changes are typed drafts that require an
explicit approval. The Purchase Check screen compares a planned purchase with
the current safe-to-spend result and a user-selected cooling-off date.

English, French, and Arabic are built in. Arabic uses right-to-left layout and a
bundled Noto Sans Arabic font. The Local Coach recognizes typed questions and
amounts in all three languages, including Arabic-Indic digits.

Run quality gates from this folder:

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```
