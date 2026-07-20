from __future__ import annotations

import sys
from collections.abc import Callable, Generator
from pathlib import Path
from typing import Any

import pytest
from fastapi.testclient import TestClient


PROJECT_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(PROJECT_ROOT / "services" / "api" / "src"))
sys.path.insert(0, str(PROJECT_ROOT / "packages" / "financial_core_python" / "src"))

from money_pilot_api.config import Settings  # noqa: E402
from money_pilot_api.main import create_app  # noqa: E402


@pytest.fixture
def client() -> Generator[TestClient, None, None]:
    app = create_app(
        Settings(
            database_url="sqlite://",
            environment="test",
            jwt_secret="test-secret-that-is-long-enough-for-repeatable-tests",
            access_token_minutes=15,
            refresh_token_days=30,
        )
    )
    with TestClient(app) as test_client:
        yield test_client


@pytest.fixture
def register_user(
    client: TestClient,
) -> Callable[..., tuple[dict[str, str], dict[str, Any]]]:
    def _register(
        email: str = "person@example.com",
        password: str = "CorrectHorseBattery123!",
        display_name: str = "Test Person",
        currency: str = "USD",
    ) -> tuple[dict[str, str], dict[str, Any]]:
        response = client.post(
            "/api/v1/auth/register",
            json={
                "email": email,
                "password": password,
                "display_name": display_name,
                "currency": currency,
            },
        )
        assert response.status_code == 201, response.text
        body = response.json()
        return {"Authorization": f"Bearer {body['access_token']}"}, body

    return _register
