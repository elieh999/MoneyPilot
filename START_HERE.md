# Start here

MoneyPilot is delivered with a ready-to-run Windows application plus the full
source-level MVP foundation. In the packaged folder, double-click
`MoneyPilot\MoneyPilot.exe` (or `Launch MoneyPilot.cmd`) to start. No developer
tools are needed for that build.

On first launch, create a local account and save the displayed recovery code.
The account begins with zero accounts, transactions, budgets, bills, and goals.
Add only the records you choose. The Local Coach works without an API key and
answers from those records; it says when information is missing rather than
inventing values.

## Fastest local start on Windows

Install Python 3.12+ and Flutter, including the native toolchain for the device
you want to run. From this folder in PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\setup-dev.ps1
```

Start the API without Docker in terminal one:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-api.ps1 -SQLite -NoReload
```

Start Flutter in terminal two:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-flutter.ps1
```

The Flutter app uses a local sign-up and sign-in flow. Credentials are isolated
from the optional API development environment. The API's development-only test
seed still uses:

- Email: `demo@moneypilot.dev`
- Password: `DemoMoneyPilot123!`

These credentials are deliberately public development data. Never reuse them in
a deployment.

## What to open first

1. `docs/previews/money_pilot_desktop.png` and
   `docs/previews/money_pilot_mobile.png` for the implemented interface.
2. `README.md` for repository orientation.
3. `VERIFICATION.md` for test results.
4. `docs/DELIVERABLE_STATUS.md` for implemented versus deferred scope.
5. `docs/ROADMAP_TECHNICAL_DEBT.md` before entering real financial data.

The Flutter client stores each profile's financial workspace on this Windows
device and is not yet connected to FastAPI cloud sync. Passwords and recovery
codes are Argon2id-hashed, but the financial snapshot is not yet database-level
encrypted. Use Windows device encryption and a protected Windows account for
private data.
