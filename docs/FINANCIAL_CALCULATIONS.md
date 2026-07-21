# Financial calculations

MoneyPilot keeps its main money formulas in small helpers instead of spreading
them through screens and API routes. The Python implementation lives in
`packages/financial_core_python`. The Flutter equivalents live in
`apps/money_pilot/lib/src/finance_engine.dart`.

Shared examples in `packages/financial_contracts/vectors.json` check that both
runtimes agree on safe spending, savings rate, and budget status.

## Money and rounding

- Money is stored as integer minor units, such as cents.
- Ratios are returned as integer basis points, where `10_000` means 100 percent.
- Python uses `Decimal` and `ROUND_HALF_UP` when division or a rate requires
  rounding.
- The application does not silently combine accounts in different currencies.
  The API excludes foreign currency accounts from totals that lack a conversion
  rate.

The Python helper can multiply minor units by an explicit decimal rate. It does
not currently provide historical exchange rates, currency scale metadata, or a
conversion service.

## Dashboard totals

For the selected period:

```text
income = sum of income amounts
expenses = sum of expense amounts
net cash flow = income - expenses
savings rate = max(income - expenses, 0) / income
```

The savings rate is unavailable when income is zero or negative. The numeric
helper returns zero in that case so the interface never displays an invalid
percentage.

Transfers do not count as income or expenses. The API also treats refunds and
reimbursements as reductions to expenses.

## Budget status

```text
remaining = planned - spent
usage = spent / planned
```

Usage is expressed in basis points. A zero or negative plan returns zero usage
and a needs review state instead of pretending that unplanned spending is
healthy.

Budgets store a rollover mode, but automatic rollover processing and detailed
pace forecasting are not implemented.

## Safe spending

The implemented safe spending calculation starts with available balances and
confirmed income, then protects recorded commitments:

```text
raw safe spending = available balance
                  + confirmed income
                  - pending outflows
                  - upcoming required bills
                  - minimum debt payments supplied by the caller
                  - planned savings
                  - goal contributions
                  - emergency reserve supplied by the caller
                  - credit card obligations supplied by the caller
                  - safety buffer
                  - known one time expenses
                  - forecast uncertainty buffer

safe spending = max(raw safe spending, 0)
```

When a remaining discretionary budget is provided, the final amount is the
lower of available liquidity and the nonnegative budget remainder. The Python
result also returns the raw amount, shortfall, total protected amount, and a
deduction breakdown.

The Flutter client uses the same core policy. Its current input does not include
a separate forecast uncertainty field.

## Allowance and forecast

The Python helper calculates a daily allowance with integer division:

```text
daily allowance = safe spending / number of days
```

The Flutter reports screen also shows a simple six month cash projection. It
continues the current monthly income, expense, and open bill totals. This is a
straight line planning estimate, not a probabilistic forecast.

## Tested behavior

The shared test vectors and unit tests cover:

- negative cash flow and zero income
- safe spending deductions, shortfalls, and budget caps
- budget variance and usage rounding
- midpoint rounding
- large integer values
- explicit decimal rate conversion
- transfer and refund behavior in the API
- exclusion of foreign currency accounts when no rate is available

## Planned calculations

MoneyPilot does not yet implement:

- historical currency conversion
- irregular income models
- budget pace and automatic rollover calculations
- emergency fund coverage history
- debt amortization, snowball, or avalanche plans
- subscription price history
- income reliability or forecast confidence scores
- complete asset and liability valuation history

Those features require their own data models, clear product rules, and tests
before they should be documented as working behavior.
