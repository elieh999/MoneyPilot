# MoneyPilot financial core (Python)

This package contains deterministic financial formulas shared by the API,
background jobs, and AI tools. Monetary inputs and outputs are integer minor
units (for example, cents). Ratios use basis points, where `10_000` means 100%.

Currency conversion uses `Decimal` exchange rates and `ROUND_HALF_UP`. The
safe-to-spend result exposes both the raw liquidity result and a non-negative,
optional-budget-capped spendable amount so shortfalls cannot be presented as
spendable money. Product-policy vectors live in the sibling
`financial_contracts` package and are executed by this package's tests.


Run its tests from this directory:

```powershell
python -m pytest
```
