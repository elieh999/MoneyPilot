# MoneyPilot

This is my personal finance app. I got tired of budgeting tools that either want
my bank login or turn into a spreadsheet with extra steps, so I wrote one that
keeps everything on my own machine and still does the arithmetic properly.

You track accounts, transactions, budgets, bills and savings goals. There is a
spending calendar, a few reports, a purchase check for when you are talking
yourself into something, and a small coach that answers questions using only the
records you actually entered. No cloud account needed. The Windows build runs on
its own without the API.

The interface is in English, French and Arabic, including right to left layout
for Arabic.

It is still a work in progress. Windows is the target I actually build and test.

## Screenshots

| Windows application | Narrow layout preview |
| --- | --- |
| ![MoneyPilot Windows dashboard](docs/previews/money_pilot_desktop.png) | ![MoneyPilot responsive onboarding layout](docs/previews/money_pilot_mobile.png) |

## What actually works

- Local account creation, sign in, recovery codes, sign out and account deletion
- Each local profile gets its own financial data, kept separate from the others
- Accounts, transactions, categories, budgets, bills and goals
- CSV import and export for transactions, with row validation and duplicate checks
- Recurring weekly and monthly transaction insights
- Calendar summaries by day and by month
- Reports, forecasting and a purchase affordability check
- English, French and Arabic interface text
- Light, dark, system and high contrast appearance options
- Ocean, cyan, forest, violet and sunset colour palettes
- A local coach that answers from the active profile's data and has to ask before
  it changes anything
- A FastAPI service for authentication and financial records, with the coach
  proposal and approval flow
- Flutter and Python test suites that both run from one script

## Where it runs

| Target | Status |
| --- | --- |
| Windows | Built, tested, launch checked, and published as a download |
| Android | Flutter runner scaffold only. No APK or device test yet |
| iOS | Flutter runner scaffold only. No IPA or device test yet |
| macOS | Flutter runner scaffold only. Not built or tested |
| Linux | Flutter runner scaffold only. Not built or tested |

There are responsive widget tests covering narrow layouts and Arabic right to
left screens, but a widget test is not the same thing as running on a real
phone, and I have not done that yet.

## Getting started on Windows

Download the repo as a ZIP, extract the whole folder, and double click
`MoneyPilot.exe` at the top level. You do not need Flutter, Python, Docker or
PowerShell for this. Keep `MoneyPilot.exe` next to the `MoneyPilot Runtime`
folder or it will not find the runtime.

Windows SmartScreen will probably warn you, because this build is not code
signed.

## Running from source

You need Python 3.12 or newer and Flutter stable.

```powershell
.\scripts\setup-dev.ps1
.\scripts\run-api.ps1 -SQLite
```

Then start the Flutter client in a second terminal:

```powershell
.\scripts\run-flutter.ps1
```

Docker is optional. The API is happy with SQLite for local work, and the Flutter
client runs fine with no API at all. See [Development](docs/DEVELOPMENT.md) for
the Docker commands and the problems I keep running into.

## Tests

Everything runs from one script at the repo root:

```powershell
.\scripts\check.ps1
```

That runs the Python tests, Ruff formatting and linting, Dart formatting,
Flutter analysis and the Flutter tests. It skips whichever tools you have not
installed instead of failing.

## Project layout

```text
apps/money_pilot/               Flutter client
services/api/                   FastAPI service
packages/financial_core_python/ Shared calculation code
packages/financial_contracts/   Calculation test data
infrastructure/                 Local Docker services
scripts/                        PowerShell helpers
docs/                           Technical notes and screenshots
```

## How the money math works

- Every amount is an integer number of minor units. No floats anywhere near a
  balance, so no surprise rounding.
- Transfers between your own accounts are not income and not an expense.
- Percentages are basis points, rounded half away from zero.
- The Dart and Python implementations are checked against the same shared test
  vectors in `packages/financial_contracts/vectors.json`, so the two sides cannot
  quietly drift apart.
- Every API resource is checked against the signed in owner.
- Local passwords and recovery codes are hashed with Argon2id.
- Local snapshots use authenticated AES GCM encryption, and older plaintext
  snapshots get migrated automatically.

## Known limitations

These are the things I know are not right yet.

- The Flutter client saves a local snapshot rather than a properly synchronised
  database. It works, but it is not real sync.
- A Flutter local profile and a FastAPI account are two separate identities. The
  client can authenticate against the API but it does not upload your records.
- The API can deduct a forecast uncertainty buffer from the safe to spend figure,
  and the Dart engine has no equivalent input. It defaults to zero so the two
  agree today, but they would disagree if anything ever passed it.
- Remote AI providers are not wired up. The coach is local and rule based.
- The local encryption key sits in app preferences, not in a hardware backed key
  store. Good enough to stop casual snooping, not good enough for a stolen disk.
- No store signing, no hosted infrastructure, no production monitoring.
- If you keep a checkout inside OneDrive, Flutter sometimes cannot delete its own
  generated folders because OneDrive turns them into reparse points. Deleting
  `build` and the platform `ephemeral` folders clears it. Pausing OneDrive or
  working in a normal local folder avoids it.

The rest of the unfinished work is in the [roadmap](docs/ROADMAP.md).

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Data model](docs/DATA_MODEL.md)
- [Development and testing](docs/DEVELOPMENT.md)
- [Financial calculations](docs/FINANCIAL_CALCULATIONS.md)
- [Local coach](docs/COACH.md)
- [API](services/api/README.md)

## Contributing

Bug reports and small focused pull requests are welcome. Have a look at
[CONTRIBUTING.md](CONTRIBUTING.md) first.

## License

MIT, see [LICENSE](LICENSE). The bundled fonts and platform files keep their own
licenses, listed in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
