"""Pure personal-finance calculations.

All money values are integer minor units. This module deliberately avoids
binary floating-point arithmetic and contains no database or framework code.
"""

from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal, ROUND_HALF_UP
from typing import Iterable


def _require_int(name: str, value: int) -> None:
    if isinstance(value, bool) or not isinstance(value, int):
        raise TypeError(f"{name} must be an integer number of minor units")


def _require_non_negative(name: str, value: int) -> None:
    _require_int(name, value)
    if value < 0:
        raise ValueError(f"{name} cannot be negative")


@dataclass(frozen=True, slots=True)
class DashboardTotals:
    income_minor: int
    expenses_minor: int
    net_cash_flow_minor: int
    savings_rate_basis_points: int


@dataclass(frozen=True, slots=True)
class SafeToSpendInput:
    available_balance_minor: int
    pending_outflows_minor: int = 0
    upcoming_required_bills_minor: int = 0
    debt_minimum_payments_minor: int = 0
    planned_savings_minor: int = 0
    goal_contributions_minor: int = 0
    confirmed_income_minor: int = 0
    emergency_reserve_minor: int = 0
    credit_card_obligations_minor: int = 0
    safety_buffer_minor: int = 0
    known_one_time_expenses_minor: int = 0
    forecast_uncertainty_buffer_minor: int = 0
    budget_remaining_minor: int | None = None


@dataclass(frozen=True, slots=True)
class SafeToSpendResult:
    safe_to_spend_minor: int
    raw_safe_to_spend_minor: int
    shortfall_minor: int
    minimum_untouched_minor: int
    available_balance_minor: int
    confirmed_income_minor: int
    deductions: dict[str, int]


def savings_rate_basis_points(income_minor: int, expenses_minor: int) -> int:
    """Return savings rate in basis points, rounded half-up.

    Zero or negative income has no meaningful savings rate and returns zero.
    Product policy clamps negative savings to zero.
    """

    _require_int("income_minor", income_minor)
    _require_non_negative("expenses_minor", expenses_minor)
    if income_minor <= 0:
        return 0
    saved = max(income_minor - expenses_minor, 0)
    return int(
        (Decimal(saved) * Decimal(10_000) / Decimal(income_minor)).quantize(
            Decimal("1"), rounding=ROUND_HALF_UP
        )
    )


def calculate_dashboard_totals(
    income_amounts_minor: Iterable[int], expense_amounts_minor: Iterable[int]
) -> DashboardTotals:
    income_values = tuple(income_amounts_minor)
    expense_values = tuple(expense_amounts_minor)
    for amount in income_values:
        _require_non_negative("income amount", amount)
    for amount in expense_values:
        _require_non_negative("expense amount", amount)
    income = sum(income_values)
    expenses = sum(expense_values)
    return DashboardTotals(
        income_minor=income,
        expenses_minor=expenses,
        net_cash_flow_minor=income - expenses,
        savings_rate_basis_points=savings_rate_basis_points(income, expenses),
    )


def calculate_safe_to_spend(values: SafeToSpendInput) -> SafeToSpendResult:
    _require_int("available_balance_minor", values.available_balance_minor)
    deduction_fields = (
        "pending_outflows_minor",
        "upcoming_required_bills_minor",
        "debt_minimum_payments_minor",
        "planned_savings_minor",
        "goal_contributions_minor",
        "emergency_reserve_minor",
        "credit_card_obligations_minor",
        "safety_buffer_minor",
        "known_one_time_expenses_minor",
        "forecast_uncertainty_buffer_minor",
    )
    deductions: dict[str, int] = {}
    for field_name in deduction_fields:
        amount = getattr(values, field_name)
        _require_non_negative(field_name, amount)
        deductions[field_name] = amount
    _require_non_negative("confirmed_income_minor", values.confirmed_income_minor)
    if values.budget_remaining_minor is not None:
        _require_int("budget_remaining_minor", values.budget_remaining_minor)
    minimum_untouched = sum(deductions.values())
    raw = (
        values.available_balance_minor
        + values.confirmed_income_minor
        - minimum_untouched
    )
    liquidity_ceiling = max(raw, 0)
    safe_to_spend = liquidity_ceiling
    if values.budget_remaining_minor is not None:
        safe_to_spend = min(liquidity_ceiling, max(values.budget_remaining_minor, 0))
    return SafeToSpendResult(
        safe_to_spend_minor=safe_to_spend,
        raw_safe_to_spend_minor=raw,
        shortfall_minor=max(-raw, 0),
        minimum_untouched_minor=minimum_untouched,
        available_balance_minor=values.available_balance_minor,
        confirmed_income_minor=values.confirmed_income_minor,
        deductions=deductions,
    )


def budget_variance(planned_minor: int, spent_minor: int) -> int:
    _require_non_negative("planned_minor", planned_minor)
    _require_non_negative("spent_minor", spent_minor)
    return planned_minor - spent_minor


def budget_burn_rate_basis_points(planned_minor: int, spent_minor: int) -> int:
    _require_non_negative("planned_minor", planned_minor)
    _require_non_negative("spent_minor", spent_minor)
    if planned_minor <= 0:
        return 0
    return int(
        (Decimal(spent_minor) * Decimal(10_000) / Decimal(planned_minor)).quantize(
            Decimal("1"), rounding=ROUND_HALF_UP
        )
    )


def allowance_for_period(safe_to_spend_minor: int, days: int) -> int:
    _require_int("safe_to_spend_minor", safe_to_spend_minor)
    if days <= 0:
        raise ValueError("days must be positive")
    if safe_to_spend_minor <= 0:
        return 0
    return safe_to_spend_minor // days


def convert_minor_units(amount_minor: int, rate: Decimal | str) -> int:
    """Convert minor units at a positive rate using ROUND_HALF_UP."""

    _require_int("amount_minor", amount_minor)
    decimal_rate = Decimal(rate)
    if not decimal_rate.is_finite() or decimal_rate <= 0:
        raise ValueError("rate must be a finite positive decimal")
    return int(
        (Decimal(amount_minor) * decimal_rate).quantize(
            Decimal("1"), rounding=ROUND_HALF_UP
        )
    )
