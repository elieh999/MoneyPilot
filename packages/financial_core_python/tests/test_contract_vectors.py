import json
from pathlib import Path

from money_pilot_financial_core import (
    SafeToSpendInput,
    budget_burn_rate_basis_points,
    budget_variance,
    calculate_safe_to_spend,
    savings_rate_basis_points,
)


VECTORS_PATH = (
    Path(__file__).resolve().parents[2] / "financial_contracts" / "vectors.json"
)


def _vectors() -> dict:
    return json.loads(VECTORS_PATH.read_text(encoding="utf-8"))


def test_safe_to_spend_contract_vectors() -> None:
    for vector in _vectors()["safe_to_spend"]:
        values = vector["input"]
        result = calculate_safe_to_spend(
            SafeToSpendInput(
                available_balance_minor=values["available_minor"],
                confirmed_income_minor=values["confirmed_income_minor"],
                pending_outflows_minor=values["pending_outgoing_minor"],
                upcoming_required_bills_minor=values["required_bills_minor"],
                debt_minimum_payments_minor=values["minimum_debt_minor"],
                planned_savings_minor=values["planned_savings_minor"],
                goal_contributions_minor=values["goal_contributions_minor"],
                emergency_reserve_minor=values["emergency_reserve_minor"],
                credit_card_obligations_minor=values["credit_obligations_minor"],
                safety_buffer_minor=values["safety_buffer_minor"],
                known_one_time_expenses_minor=values["known_required_minor"],
                budget_remaining_minor=values["budget_remaining_minor"],
            )
        )
        assert result.safe_to_spend_minor == vector["expected_minor"], vector["name"]


def test_savings_rate_contract_vectors() -> None:
    for vector in _vectors()["savings_rate"]:
        values = vector["input"]
        assert (
            savings_rate_basis_points(values["income_minor"], values["expense_minor"])
            == vector["expected_basis_points"]
        ), vector["name"]


def test_budget_status_contract_vectors() -> None:
    for vector in _vectors()["budget_status"]:
        values = vector["input"]
        expected = vector["expected"]
        assert (
            budget_variance(values["planned_minor"], values["spent_minor"])
            == expected["remaining_minor"]
        ), vector["name"]
        assert (
            budget_burn_rate_basis_points(
                values["planned_minor"], values["spent_minor"]
            )
            == expected["usage_basis_points"]
        ), vector["name"]
