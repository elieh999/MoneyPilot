from datetime import timedelta

from fastapi.testclient import TestClient

from money_pilot_api.models import AIActionProposal, utc_now


def test_sync_create_is_idempotent_and_stale_update_conflicts(
    client: TestClient, register_user
) -> None:
    headers, _ = register_user()
    create_payload = {
        "operations": [
            {
                "client_operation_id": "device-a-0001",
                "entity_type": "account",
                "operation": "create",
                "payload": {
                    "name": "Offline cash",
                    "account_type": "cash",
                    "currency": "USD",
                    "balance_minor": 12_345,
                },
            }
        ]
    }
    first = client.post("/api/v1/sync/operations", headers=headers, json=create_payload)
    assert first.status_code == 200, first.text
    result = first.json()["operations"][0]
    assert result["status"] == "applied"
    assert result["replayed"] is False
    entity_id = result["entity_id"]

    replay = client.post(
        "/api/v1/sync/operations", headers=headers, json=create_payload
    )
    assert replay.status_code == 200
    assert replay.json()["operations"][0]["replayed"] is True
    assert len(client.get("/api/v1/accounts", headers=headers).json()) == 1

    update = client.post(
        "/api/v1/sync/operations",
        headers=headers,
        json={
            "operations": [
                {
                    "client_operation_id": "device-a-0002",
                    "entity_type": "account",
                    "entity_id": entity_id,
                    "operation": "update",
                    "base_version": 1,
                    "payload": {"name": "Synced cash"},
                }
            ]
        },
    )
    assert update.json()["operations"][0]["server_version"] == 2
    stale = client.post(
        "/api/v1/sync/operations",
        headers=headers,
        json={
            "operations": [
                {
                    "client_operation_id": "device-b-0001",
                    "entity_type": "account",
                    "entity_id": entity_id,
                    "operation": "update",
                    "base_version": 1,
                    "payload": {"name": "Stale name"},
                }
            ]
        },
    )
    assert stale.status_code == 200
    assert stale.json()["operations"][0]["status"] == "conflict"
    assert (
        client.get(f"/api/v1/accounts/{entity_id}", headers=headers).json()["name"]
        == "Synced cash"
    )


def test_ai_uses_allowlisted_read_tool_and_requires_approval_for_write(
    client: TestClient, register_user
) -> None:
    headers, _ = register_user()
    client.post(
        "/api/v1/accounts",
        headers=headers,
        json={
            "name": "Checking",
            "account_type": "checking",
            "currency": "USD",
            "balance_minor": 100_000,
        },
    )
    safe = client.post(
        "/api/v1/ai/chat",
        headers=headers,
        json={"message": "How much is safe to spend?"},
    )
    assert safe.status_code == 200
    assert safe.json()["tool_name"] == "get_safe_to_spend"
    assert "professional financial" in safe.json()["disclaimer"]
    assert safe.json()["proposal"] is None

    draft = client.post(
        "/api/v1/ai/chat",
        headers=headers,
        json={"message": "Create a budget for me"},
    )
    assert draft.status_code == 200, draft.text
    assert draft.json()["tool_name"] == "propose_budget"
    proposal = draft.json()["proposal"]
    assert proposal["status"] == "pending"
    assert client.get("/api/v1/budgets", headers=headers).json() == []

    approved = client.post(
        f"/api/v1/ai/proposals/{proposal['id']}/approve", headers=headers
    )
    assert approved.status_code == 200, approved.text
    assert approved.json()["proposal"]["status"] == "approved"
    assert len(client.get("/api/v1/budgets", headers=headers).json()) == 1
    second_approval = client.post(
        f"/api/v1/ai/proposals/{proposal['id']}/approve", headers=headers
    )
    assert second_approval.status_code == 409


def test_ai_proposals_are_owner_scoped(client: TestClient, register_user) -> None:
    first_headers, _ = register_user(email="ai-one@example.com")
    second_headers, _ = register_user(email="ai-two@example.com")
    draft = client.post(
        "/api/v1/ai/chat",
        headers=first_headers,
        json={"message": "Draft a budget"},
    ).json()
    proposal_id = draft["proposal"]["id"]
    assert (
        client.post(
            f"/api/v1/ai/proposals/{proposal_id}/approve", headers=second_headers
        ).status_code
        == 404
    )


def test_ai_proposal_expiry_and_payload_tampering_are_rejected(
    client: TestClient, register_user
) -> None:
    headers, _ = register_user()
    expired_draft = client.post(
        "/api/v1/ai/chat",
        headers=headers,
        json={"message": "Create a budget"},
    ).json()["proposal"]
    with client.app.state.database.session_factory() as db:
        proposal = db.get(AIActionProposal, expired_draft["id"])
        assert proposal is not None
        proposal.expires_at = utc_now() - timedelta(seconds=1)
        db.commit()
    expired = client.post(
        f"/api/v1/ai/proposals/{expired_draft['id']}/approve", headers=headers
    )
    assert expired.status_code == 409
    assert "expired" in expired.json()["detail"].lower()

    tampered_draft = client.post(
        "/api/v1/ai/chat",
        headers=headers,
        json={"message": "Draft a budget"},
    ).json()["proposal"]
    with client.app.state.database.session_factory() as db:
        proposal = db.get(AIActionProposal, tampered_draft["id"])
        assert proposal is not None
        proposal.payload = {**proposal.payload, "planned_minor": 999_999_999}
        db.commit()
    tampered = client.post(
        f"/api/v1/ai/proposals/{tampered_draft['id']}/approve", headers=headers
    )
    assert tampered.status_code == 409
    assert "integrity" in tampered.json()["detail"].lower()
    assert client.get("/api/v1/budgets", headers=headers).json() == []


def test_development_seed_is_idempotent_and_demo_can_login(client: TestClient) -> None:
    first = client.post("/api/v1/dev/seed-demo")
    assert first.status_code == 200, first.text
    assert first.json()["seeded"] is True
    second = client.post("/api/v1/dev/seed-demo")
    assert second.status_code == 200
    assert second.json()["seeded"] is False
    login = client.post(
        "/api/v1/auth/login",
        json={"email": first.json()["email"], "password": first.json()["password"]},
    )
    assert login.status_code == 200
    headers = {"Authorization": f"Bearer {login.json()['access_token']}"}
    summary = client.get("/api/v1/dashboard/summary", headers=headers)
    assert summary.status_code == 200
    assert summary.json()["current_month_income_minor"] == 250_000


def test_health_openapi_and_correlation_id(client: TestClient) -> None:
    live = client.get("/health/live", headers={"X-Request-ID": "test-correlation"})
    assert live.status_code == 200
    assert live.headers["X-Request-ID"] == "test-correlation"
    assert client.get("/health/ready").json() == {"status": "ready"}
    openapi = client.get("/openapi.json")
    assert openapi.status_code == 200
    assert "/api/v1/transactions" in openapi.json()["paths"]
