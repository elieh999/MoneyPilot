from __future__ import annotations

import sys
from pathlib import Path

import pytest

PROJECT_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(PROJECT_ROOT / "services" / "api" / "src"))

from money_pilot_api.config import Settings  # noqa: E402

STRONG_SECRET = "a" * 32


def test_validate_accepts_a_strong_production_secret() -> None:
    Settings(
        environment="production",
        jwt_secret=STRONG_SECRET,
    ).validate()


def test_validate_rejects_an_empty_secret() -> None:
    with pytest.raises(ValueError, match="must not be empty"):
        Settings(environment="development", jwt_secret="").validate()


@pytest.mark.parametrize("environment", ["production", "PRODUCTION", "prod", "Prod"])
def test_validate_rejects_a_short_secret_in_production(environment: str) -> None:
    with pytest.raises(ValueError, match="non-placeholder"):
        Settings(environment=environment, jwt_secret="a" * 31).validate()


@pytest.mark.parametrize(
    "secret",
    [
        "CHANGE_ME" + "a" * 40,
        "change_me" + "a" * 40,
        "YOUR_" + "a" * 40,
        "your_" + "a" * 40,
    ],
)
def test_validate_rejects_placeholder_secrets_in_production(secret: str) -> None:
    with pytest.raises(ValueError, match="non-placeholder"):
        Settings(environment="production", jwt_secret=secret).validate()


def test_validate_allows_a_short_secret_outside_production() -> None:
    Settings(environment="development", jwt_secret="short-dev-secret").validate()


@pytest.mark.parametrize(
    ("access_token_minutes", "refresh_token_days"),
    [(0, 30), (-1, 30), (15, 0), (15, -1)],
)
def test_validate_rejects_non_positive_token_lifetimes(
    access_token_minutes: int, refresh_token_days: int
) -> None:
    with pytest.raises(ValueError, match="token lifetimes must be positive"):
        Settings(
            environment="development",
            jwt_secret=STRONG_SECRET,
            access_token_minutes=access_token_minutes,
            refresh_token_days=refresh_token_days,
        ).validate()


def test_from_env_requires_an_explicit_secret_in_production(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setenv("MONEY_PILOT_ENVIRONMENT", "production")
    monkeypatch.delenv("MONEY_PILOT_JWT_SECRET", raising=False)
    with pytest.raises(ValueError, match="production requires MONEY_PILOT_JWT_SECRET"):
        Settings.from_env()


def test_from_env_generates_a_development_secret_when_none_is_set(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setenv("MONEY_PILOT_ENVIRONMENT", "development")
    monkeypatch.delenv("MONEY_PILOT_JWT_SECRET", raising=False)
    settings = Settings.from_env()
    assert settings.jwt_secret
    assert len(settings.jwt_secret) >= 32
