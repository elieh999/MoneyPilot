# Shared financial examples

MoneyPilot has two runtime implementations of its money calculations: Python on
the API and Dart on the client. This package contains the shared examples
between them.

All monetary inputs and outputs are integer minor units. Percentages are integer
basis points (`1% == 100`), dates use ISO 8601, and calculations never infer an
exchange rate. Each runtime should execute every vector in `vectors.json`.

## Safe to spend

The liquidity ceiling is:

```text
included available balances
+ confirmed income before the horizon
- pending outgoing transactions
- required bills before the horizon
- minimum debt payments before the horizon
- planned savings and goal contributions
- emergency reserve
- credit card obligations due before the horizon
- user safety buffer
- known required expenses that occur once
```

The result is never below zero. If a discretionary budget remainder is supplied,
safe spending is the lower of the liquidity ceiling, limited to zero or greater, and the
budget remainder, limited to zero or greater. Excluded accounts and obligations must be removed
before calling the calculation.

## Savings rate

```text
max(0, income - expense) / income
```

The output is basis points rounded half away from zero. When income is zero or
negative, the rate is zero and the UI must label it unavailable rather than
claiming a meaningful percentage.

## Budget status

Budget remaining is `planned - spent`; variance may be negative. Usage basis
points are `spent / planned`, rounded half away from zero. A zero or negative
plan reports zero usage and is treated as needing review.

These formulas are product policy, not financial advice. A change requires an
architecture decision record and updated conformance vectors in the same commit.
