from datetime import timedelta

from fastapi.testclient import TestClient

from money_pilot_api.models import utc_now


def test_budget_bill_goal_crud_and_safe_to_spend(
    client: TestClient, register_user
) -> None:
    headers, _ = register_user()
    account = client.post(
        "/api/v1/accounts",
        headers=headers,
        json={
            "name": "Checking",
            "account_type": "checking",
            "currency": "USD",
            "balance_minor": 200_000,
        },
    ).json()
    today = utc_now().date()
    budget = client.post(
        "/api/v1/budgets",
        headers=headers,
        json={
            "name": "Flexible",
            "period_start": today.isoformat(),
            "period_end": (today + timedelta(days=29)).isoformat(),
            "planned_minor": 100_000,
        },
    )
    assert budget.status_code == 201
    bill = client.post(
        "/api/v1/bills",
        headers=headers,
        json={
            "name": "Rent",
            "amount_minor": 80_000,
            "currency": "USD",
            "due_date": (today + timedelta(days=7)).isoformat(),
            "recurrence": "monthly",
            "account_id": account["id"],
        },
    )
    assert bill.status_code == 201
    goal = client.post(
        "/api/v1/goals",
        headers=headers,
        json={
            "name": "Emergency fund",
            "target_minor": 500_000,
            "current_minor": 50_000,
            "currency": "USD",
            "linked_account_id": account["id"],
            "priority": 1,
        },
    )
    assert goal.status_code == 201

    safe = client.get(
        "/api/v1/safe-to-spend",
        headers=headers,
        params={
            "until_date": (today + timedelta(days=30)).isoformat(),
            "planned_savings_minor": 20_000,
            "safety_buffer_minor": 25_000,
        },
    )
    assert safe.status_code == 200, safe.text
    assert safe.json()["safe_to_spend_minor"] == 75_000
    assert safe.json()["deductions"]["upcoming_required_bills_minor"] == 80_000
    assert safe.json()["minimum_untouched_minor"] == 125_000

    dashboard = client.get("/api/v1/dashboard/summary", headers=headers).json()
    assert dashboard["upcoming_bills_minor"] == 80_000
    assert dashboard["goal_saved_minor"] == 50_000
    assert dashboard["goal_target_minor"] == 500_000
    assert dashboard["safe_to_spend_minor"] == 120_000

    updated_goal = client.patch(
        f"/api/v1/goals/{goal.json()['id']}",
        headers=headers,
        json={"current_minor": 75_000, "version": goal.json()["version"]},
    )
    assert updated_goal.status_code == 200
    assert updated_goal.json()["current_minor"] == 75_000


def test_safe_to_spend_reports_shortfall_not_negative_spendable_money(
    client: TestClient, register_user
) -> None:
    headers, _ = register_user()
    client.post(
        "/api/v1/accounts",
        headers=headers,
        json={
            "name": "Small balance",
            "account_type": "checking",
            "currency": "USD",
            "balance_minor": 10_000,
        },
    )
    response = client.get(
        "/api/v1/safe-to-spend",
        headers=headers,
        params={"emergency_reserve_minor": 30_000},
    )
    assert response.status_code == 200
    assert response.json()["safe_to_spend_minor"] == 0
    assert response.json()["raw_safe_to_spend_minor"] == -20_000
    assert response.json()["shortfall_minor"] == 20_000


def test_foreign_currency_accounts_are_not_summed_without_conversion(
    client: TestClient, register_user
) -> None:
    headers, _ = register_user(currency="USD")
    for currency in ("USD", "EUR"):
        client.post(
            "/api/v1/accounts",
            headers=headers,
            json={
                "name": currency,
                "account_type": "checking",
                "currency": currency,
                "balance_minor": 100_000,
            },
        )
    summary = client.get("/api/v1/dashboard/summary", headers=headers).json()
    assert summary["total_available_balance_minor"] == 100_000
    assert summary["excluded_currency_account_count"] == 1
