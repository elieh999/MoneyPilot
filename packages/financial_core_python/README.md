# MoneyPilot financial core (Python)

This package contains consistent financial formulas shared by the API,
background jobs, and AI tools. Monetary inputs and outputs are integer minor
units (for example, cents). Ratios use basis points, where `10_000` means 100%.

Currency conversion uses `Decimal` exchange rates and `ROUND_HALF_UP`. The
safe spending result exposes both the raw liquidity result and a value that is never below zero,
optional spending amount limited by the budget so shortfalls cannot be presented as
spendable money. Shared behavior examples live in the sibling
`financial_contracts` package and are checked by this package's tests.


Run its tests from this directory:

```powershell
python -m pytest
```
