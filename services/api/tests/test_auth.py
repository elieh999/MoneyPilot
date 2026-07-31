from fastapi.testclient import TestClient
from sqlalchemy import select

from money_pilot_api.models import User


def test_registration_login_me_and_default_categories(
    client: TestClient, register_user
) -> None:
    headers, registered = register_user(email="Case@Test.Example")
    assert registered["user"]["email"] == "case@test.example"
    assert "password" not in registered["user"]
    with client.app.state.database.session_factory() as db:
        stored_user = db.scalar(select(User).where(User.email == "case@test.example"))
        assert stored_user is not None
        assert stored_user.password_hash.startswith("$argon2id$")
        assert "CorrectHorseBattery123!" not in stored_user.password_hash

    me = client.get("/api/v1/auth/me", headers=headers)
    assert me.status_code == 200
    assert me.json()["display_name"] == "Test Person"

    categories = client.get("/api/v1/categories", headers=headers)
    assert categories.status_code == 200
    assert {item["name"] for item in categories.json()} >= {
        "Salary",
        "Groceries",
        "Savings",
    }

    bad_login = client.post(
        "/api/v1/auth/login",
        json={"email": "case@test.example", "password": "incorrect"},
    )
    assert bad_login.status_code == 401
    good_login = client.post(
        "/api/v1/auth/login",
        json={
            "email": "case@test.example",
            "password": "CorrectHorseBattery123!",
        },
    )
    assert good_login.status_code == 200


def test_refresh_rotation_detects_reuse_and_revokes_session(
    client: TestClient, register_user
) -> None:
    _, registered = register_user()
    original_refresh = registered["refresh_token"]
    rotated = client.post(
        "/api/v1/auth/refresh", json={"refresh_token": original_refresh}
    )
    assert rotated.status_code == 200
    assert rotated.json()["refresh_token"] != original_refresh

    reuse = client.post(
        "/api/v1/auth/refresh", json={"refresh_token": original_refresh}
    )
    assert reuse.status_code == 401
    assert "reuse" in reuse.json()["detail"].lower()

    after_reuse = client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": rotated.json()["refresh_token"]},
    )
    assert after_reuse.status_code == 401


def test_logout_invalidates_current_access_token(
    client: TestClient, register_user
) -> None:
    headers, _ = register_user()
    assert client.post("/api/v1/auth/logout", headers=headers).status_code == 200
    assert client.get("/api/v1/auth/me", headers=headers).status_code == 401


def test_duplicate_registration_and_unauthenticated_access(
    client: TestClient, register_user
) -> None:
    register_user()
    duplicate = client.post(
        "/api/v1/auth/register",
        json={
            "email": "person@example.com",
            "password": "CorrectHorseBattery123!",
            "display_name": "Another",
            "currency": "USD",
        },
    )
    assert duplicate.status_code == 409
    assert client.get("/api/v1/accounts").status_code == 401


def test_registration_rejects_passwords_that_bypass_client_strength_rules(
    client: TestClient,
) -> None:
    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": "weak-password@test.example",
            "password": "alllowercase123",
            "display_name": "Weak Password",
            "currency": "USD",
        },
    )

    assert response.status_code == 422
    assert "uppercase, lowercase, and numeric" in response.text

