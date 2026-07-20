from decimal import Decimal

import pytest

from money_pilot_financial_core import (
    SafeToSpendInput,
    allowance_for_period,
    budget_burn_rate_basis_points,
    budget_variance,
    calculate_dashboard_totals,
    calculate_safe_to_spend,
    convert_minor_units,
    savings_rate_basis_points,
)


def test_dashboard_totals_and_negative_cash_flow() -> None:
    totals = calculate_dashboard_totals([250_000, 50_000], [125_000, 200_000])
    assert totals.income_minor == 300_000
    assert totals.expenses_minor == 325_000
    assert totals.net_cash_flow_minor == -25_000
    assert totals.savings_rate_basis_points == 0


@pytest.mark.parametrize(
    ("income", "expenses", "expected"),
    [(0, 0, 0), (100, 0, 10_000), (100, 33, 6_700), (100, 150, 0)],
)
def test_savings_rate_edge_cases(income: int, expenses: int, expected: int) -> None:
    assert savings_rate_basis_points(income, expenses) == expected


def test_safe_to_spend_exposes_shortfall_and_complete_breakdown() -> None:
    result = calculate_safe_to_spend(
        SafeToSpendInput(
            available_balance_minor=100_000,
            upcoming_required_bills_minor=70_000,
            planned_savings_minor=20_000,
            safety_buffer_minor=25_000,
            confirmed_income_minor=5_000,
        )
    )
    assert result.raw_safe_to_spend_minor == -10_000
    assert result.safe_to_spend_minor == 0
    assert result.shortfall_minor == 10_000
    assert result.minimum_untouched_minor == 115_000
    assert result.deductions["upcoming_required_bills_minor"] == 70_000


def test_safe_to_spend_accepts_negative_account_balance_but_not_negative_obligation() -> (
    None
):
    result = calculate_safe_to_spend(SafeToSpendInput(available_balance_minor=-500))
    assert result.shortfall_minor == 500
    with pytest.raises(ValueError):
        calculate_safe_to_spend(
            SafeToSpendInput(
                available_balance_minor=100,
                upcoming_required_bills_minor=-1,
            )
        )


def test_budget_and_allowance_edges() -> None:
    assert budget_variance(10_000, 12_500) == -2_500
    assert budget_burn_rate_basis_points(0, 1) == 0
    assert budget_burn_rate_basis_points(10_000, 12_500) == 12_500
    assert allowance_for_period(100, 3) == 33
    assert allowance_for_period(-100, 3) == 0
    with pytest.raises(ValueError):
        allowance_for_period(100, 0)


def test_currency_conversion_rounding_large_and_negative_values() -> None:
    assert convert_minor_units(101, Decimal("1.005")) == 102
    assert convert_minor_units(-101, "1.005") == -102
    assert convert_minor_units(9_000_000_000_000, "1.25") == 11_250_000_000_000
    with pytest.raises(ValueError):
        convert_minor_units(100, "0")


def test_money_requires_integer_minor_units() -> None:
    with pytest.raises(TypeError):
        savings_rate_basis_points(100.0, 50)  # type: ignore[arg-type]
