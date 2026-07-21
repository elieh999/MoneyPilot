# Financial calculations

MoneyPilot keeps financial calculations in shared, testable helpers so the API
and client can follow the same rounding rules. The Python implementation lives
in `packages/financial_core_python`, with cross language examples in
`packages/financial_contracts/vectors.json`.

## Numeric and time rules

- Store money as signed 64-bit integer minor units with an ISO currency code.
  Inputs representing amounts are zero or greater; direction is modeled by type.
- Use `Decimal` for rates and intermediate division. Round final minor units with
  `ROUND_HALF_UP`. Never use binary float.
- A currency metadata table supplies scale, including currencies with no decimal places.
- A rate `S/R` means one major unit of source currency `S` buys `rate` major
  units of reporting currency `R`:
  `target_minor = round_half_up(source_minor / 10^scale(S) * rate * 10^scale(R))`.
  Persist rate, provider/manual source, and effective timestamp with the result.
- Reports use historical rates effective at transaction time. Missing rates mark
  totals incomplete; they never assume 1:1.
- Server instants are UTC. A budget day/payday is evaluated in the user's IANA
  timezone. Date intervals include the start but not the end unless labeled otherwise.

## Ledger totals

For posted entries in the requested interval/base currency:

- `income = sum(income magnitudes)`.
- `expenses = sum(expense magnitudes) - linked_or_unlinked_refund magnitudes`,
  floored at zero only for display; the underlying signed expense result remains
  visible when refunds exceed expenses.
- `net cash flow = income - expenses`.
- Transfers, account adjustments, opening balances, and investment valuation
  changes do not count as income or expense.
- Splits replace, rather than add to, the parent categorization amount.

The dashboard's **cash surplus rate** is
`max(income - expenses, 0) / income`; it is unavailable when income is zero or
negative. A later **allocated savings rate** is separately labeled as
`qualifying savings and principal contributions / net income`; it must not
count transfers twice when they are also represented as goal contributions.

Ratios are returned as integer basis points (`10_000 = 100%`) and rounded to the nearest value.

## Budget calculations

- `remaining = planned - spent`.
- `variance = planned - spent` (negative means over budget).
- `percentage used = spent / planned`; if planned is zero, the calculation
  returns `0` basis points plus an explicit state for unplanned spending that needs review,
  so the UI never presents that numeric fallback as healthy `0%` usage.
- `time elapsed = completed local calendar days / total calendar days`.
- `expected spent to date = planned * time elapsed`.
- `pace variance = expected spent to date - spent`.
- `forecast final = spent / completed_days * total_days` after at least one
  completed day; otherwise unavailable. Recurring known future obligations may
  replace the simple extrapolation when labeled.
- Rollover is a separate auditable line. Policy is one of none, positive,
  overspend, both, with an optional cap; it never rewrites the prior period.

Categories carry planning behavior `need`, `want`, `saving`, `debt`, or
`excluded`, enabling but not forcing 50/30/20. The template is a starting
proposal based on usable net income and remains editable.

## Safe spending estimate

For a stated horizon, normally the next payday:

```text
raw_safe_to_spend = liquid_available_balance
                  + confirmed_income_before_horizon
                  - pending_outflows_not_in_available_balance
                  - required_bills_before_horizon
                  - debt_minimums_before_horizon
                  - planned_savings_before_horizon
                  - goal_contributions_before_horizon
                  - credit_card_obligations_not_already_counted
                  - known_one_time_expenses
                  - emergency_reserve_shortfall
                  - user_safety_buffer
                  - forecast_uncertainty_buffer

liquidity_limited = max(raw_safe_to_spend, 0)
safe_to_spend = min(liquidity_limited, max(discretionary_budget_remaining, 0))
```

The budget cap is optional. `shortfall = max(-raw_safe_to_spend, 0)`. The result
returns every deduction and a `minimum_untouched` sum.

Policy for avoiding duplicate counting:

- Prefer an account's available balance. If it already includes pending card or
  bank items, do not subtract those items again.
- A scheduled card payment is deducted only for the portion not already present
  as a pending outflow from a cash account.
- A bill linked to a posted/pending transaction is satisfied and not deducted
  separately.
- Credit limits and investment values are excluded by default. The user may
  include an account, but the explanation flags liquidity risk.
- Emergency reserve deduction is only the amount within liquid accounts that
  the user marked untouchable, not the entire target again.

`daily allowance = safe_to_spend // inclusive_days_remaining`; leftover minor
units remain as buffer. `weekly allowance = min(safe_to_spend, daily * 7)`.

Example in cents: available `100000` + confirmed income `5000` - bills `70000`
- planned savings `20000` - safety buffer `25000` = raw `-10000`; spendable `0`,
shortfall `10000`, untouched deductions `115000`.

## Income planning

Net income is either entered by the user or
`gross - entered tax withholding - entered deductions`.
No jurisdictional tax estimate is implied.

Frequency normalization uses occurrences in a calendar year: weekly 52,
biweekly 26, semimonthly 24, monthly 12, quarterly 4, annual 1. Displayed monthly
equivalent is `annualized / 12`, while cash flow forecasts use actual dates.

For irregular income, the user chooses a method. The conservative default after
three complete months is the lowest of the last three monthly net totals;
before that, only confirmed future income or an explicit user baseline enters
safe spending. Estimates show the history length and selected method.

## Goals and emergency fund

- `goal remaining = max(target - current, 0)`.
- Required periodic contribution divides remaining minor units by remaining
  contribution periods and rounds up so the target is not underfunded.
- Completion forecast iterates scheduled contributions; no contribution or a
  missed fixed deadline returns an explicit unattainable/behind state.
- `essential monthly average` uses complete months of categories marked `need`,
  preferring 3-6 months and disclosing sample count.
- `emergency coverage months = liquid emergency funds / essential monthly average`;
  unavailable when essential average is zero. Credit limits are never funds.

## Debt and net worth

- `debt to income = required monthly debt payments / gross monthly income`;
  unavailable without positive gross income and labeled an estimate.
- For debt with a fixed rate, monthly rate `r`, principal `P`, and payment `A`,
  simulate month by month using rounded interest rather than relying only on a
  closed form. If `A <= first month interest`, flag a balance that will not decrease. Debt with no interest
  months are `ceil(P/A)`.
- Snowball orders by balance then ID; avalanche by APR then balance then ID.
  Minimum payments are applied first; the extra pool follows the strategy.
- `net worth = converted included assets - converted included liabilities` at a
  stated valuation date. Manual asset values are labeled and never described as
  verified.

## Other metrics

- `subscription annual cost`: monthly x12, weekly x52, biweekly x26,
  quarterly x4, annual x1; custom recurrence uses dated occurrences.
- Average daily spending divides by all local calendar days in the interval,
  including days without spending. Average transaction uses posted expense count.
- Month/year change is `(current - previous) / abs(previous)`. If previous is
  zero, percentage is unavailable and absolute change is shown.
- Rolling averages use complete periods only and report the period count.
- Income reliability draft score: with at least three complete periods,
  `clamp(100 - 100 * population_stddev / abs(mean), 0, 100)`; otherwise
  unavailable. This is consistency, not employment risk.
- Forecast confidence is a transparent heuristic, not probability: start at
  100 and subtract documented penalties for missing account reconciliation,
  sparse history, irregular income, missing exchange rates, and high recent
  variance. Display its components; AI cannot increase it.

## Required edge tests

Zero or negative cash flow, large integer values, all currency scales, midpoint
rounding, refunds, transfers, split remainders, missing/irregular income,
overdue bills, negative accounts, duplicate credit card counting, calendar
boundaries, daylight saving time, timezone travel, a goal due today, and debt whose balance will not decrease.
