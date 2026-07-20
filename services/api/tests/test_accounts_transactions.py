from fastapi.testclient import TestClient


def _account(
    client: TestClient,
    headers: dict[str, str],
    *,
    name: str = "Checking",
    balance: int = 100_000,
    currency: str = "USD",
) -> dict:
    response = client.post(
        "/api/v1/accounts",
        headers=headers,
        json={
            "name": name,
            "account_type": "checking",
            "currency": currency,
            "balance_minor": balance,
        },
    )
    assert response.status_code == 201, response.text
    return response.json()


def _transaction(
    client: TestClient,
    headers: dict[str, str],
    account_id: str,
    **overrides,
) -> dict:
    payload = {
        "transaction_type": "expense",
        "amount_minor": 25_000,
        "currency": "USD",
        "account_id": account_id,
        "description": "Test expense",
        "status": "cleared",
    }
    payload.update(overrides)
    response = client.post("/api/v1/transactions", headers=headers, json=payload)
    assert response.status_code == 201, response.text
    return response.json()


def test_cleared_pending_update_delete_and_restore_balance_semantics(
    client: TestClient, register_user
) -> None:
    headers, _ = register_user()
    account = _account(client, headers)
    cleared = _transaction(client, headers, account["id"])
    after_cleared = client.get(
        f"/api/v1/accounts/{account['id']}", headers=headers
    ).json()
    assert after_cleared["balance_minor"] == 75_000
    assert after_cleared["available_balance_minor"] == 75_000

    pending = _transaction(
        client,
        headers,
        account["id"],
        amount_minor=5_000,
        status="pending",
    )
    after_pending = client.get(
        f"/api/v1/accounts/{account['id']}", headers=headers
    ).json()
    assert after_pending["balance_minor"] == 75_000
    assert after_pending["available_balance_minor"] == 70_000

    changed = client.patch(
        f"/api/v1/transactions/{pending['id']}",
        headers=headers,
        json={"status": "cleared", "version": pending["version"]},
    )
    assert changed.status_code == 200
    after_change = client.get(
        f"/api/v1/accounts/{account['id']}", headers=headers
    ).json()
    assert after_change["balance_minor"] == 70_000
    assert after_change["available_balance_minor"] == 70_000

    deleted = client.delete(f"/api/v1/transactions/{cleared['id']}", headers=headers)
    assert deleted.status_code == 200
    assert (
        client.get(f"/api/v1/accounts/{account['id']}", headers=headers).json()[
            "balance_minor"
        ]
        == 95_000
    )

    restored = client.post(
        f"/api/v1/transactions/{cleared['id']}/restore", headers=headers
    )
    assert restored.status_code == 200
    assert (
        client.get(f"/api/v1/accounts/{account['id']}", headers=headers).json()[
            "balance_minor"
        ]
        == 70_000
    )


def test_transfer_updates_both_accounts_and_not_dashboard_cash_flow(
    client: TestClient, register_user
) -> None:
    headers, _ = register_user()
    source = _account(client, headers, name="Source", balance=100_000)
    destination = _account(client, headers, name="Savings", balance=10_000)
    transfer = _transaction(
        client,
        headers,
        source["id"],
        transaction_type="transfer",
        destination_account_id=destination["id"],
        amount_minor=30_000,
    )
    assert transfer["transaction_type"] == "transfer"
    assert (
        client.get(f"/api/v1/accounts/{source['id']}", headers=headers).json()[
            "balance_minor"
        ]
        == 70_000
    )
    assert (
        client.get(f"/api/v1/accounts/{destination['id']}", headers=headers).json()[
            "balance_minor"
        ]
        == 40_000
    )
    summary = client.get("/api/v1/dashboard/summary", headers=headers).json()
    assert summary["current_month_income_minor"] == 0
    assert summary["current_month_expenses_minor"] == 0


def test_transfer_validates_destination_before_any_balance_change(
    client: TestClient, register_user
) -> None:
    owner_headers, _ = register_user(email="owner@example.com")
    other_headers, _ = register_user(email="other@example.com")
    source = _account(client, owner_headers, balance=100_000)
    foreign_destination = _account(client, other_headers, balance=50_000)
    failed = client.post(
        "/api/v1/transactions",
        headers=owner_headers,
        json={
            "transaction_type": "transfer",
            "amount_minor": 10_000,
            "currency": "USD",
            "account_id": source["id"],
            "destination_account_id": foreign_destination["id"],
        },
    )
    assert failed.status_code == 404
    unchanged = client.get(
        f"/api/v1/accounts/{source['id']}", headers=owner_headers
    ).json()
    assert unchanged["balance_minor"] == 100_000
    assert unchanged["available_balance_minor"] == 100_000


def test_refund_offsets_expense_and_does_not_inflate_income(
    client: TestClient, register_user
) -> None:
    headers, _ = register_user()
    account = _account(client, headers, balance=0)
    _transaction(
        client,
        headers,
        account["id"],
        transaction_type="income",
        amount_minor=100_000,
    )
    _transaction(client, headers, account["id"], amount_minor=50_000)
    _transaction(
        client,
        headers,
        account["id"],
        transaction_type="refund",
        amount_minor=20_000,
    )
    summary = client.get("/api/v1/dashboard/summary", headers=headers).json()
    assert summary["current_month_income_minor"] == 100_000
    assert summary["current_month_expenses_minor"] == 30_000
    assert summary["net_cash_flow_minor"] == 70_000
    assert summary["savings_rate_basis_points"] == 7_000


def test_uuid_owner_isolation_for_accounts_and_transactions(
    client: TestClient, register_user
) -> None:
    first_headers, _ = register_user(email="first@example.com")
    second_headers, _ = register_user(email="second@example.com")
    account = _account(client, first_headers)
    transaction = _transaction(client, first_headers, account["id"])
    assert (
        client.get(
            f"/api/v1/accounts/{account['id']}", headers=second_headers
        ).status_code
        == 404
    )
    assert (
        client.get(
            f"/api/v1/transactions/{transaction['id']}", headers=second_headers
        ).status_code
        == 404
    )
    unauthorized_write = client.post(
        "/api/v1/transactions",
        headers=second_headers,
        json={
            "transaction_type": "expense",
            "amount_minor": 100,
            "currency": "USD",
            "account_id": account["id"],
        },
    )
    assert unauthorized_write.status_code == 404


def test_optimistic_concurrency_rejects_stale_account_update(
    client: TestClient, register_user
) -> None:
    headers, _ = register_user()
    account = _account(client, headers)
    first = client.patch(
        f"/api/v1/accounts/{account['id']}",
        headers=headers,
        json={"name": "Renamed", "version": account["version"]},
    )
    assert first.status_code == 200
    stale = client.patch(
        f"/api/v1/accounts/{account['id']}",
        headers=headers,
        json={"name": "Stale", "version": account["version"]},
    )
    assert stale.status_code == 409
