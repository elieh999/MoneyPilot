from __future__ import annotations

import os
import secrets
from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class Settings:
    database_url: str = "sqlite:///./money_pilot.db"
    environment: str = "development"
    jwt_secret: str = ""
    access_token_minutes: int = 15
    refresh_token_days: int = 30

    @classmethod
    def from_env(cls) -> Settings:
        environment = os.getenv("MONEY_PILOT_ENVIRONMENT", "development")
        configured_secret = os.getenv("MONEY_PILOT_JWT_SECRET", "").strip()
        if environment.lower() in {"production", "prod"} and not configured_secret:
            raise ValueError("production requires MONEY_PILOT_JWT_SECRET")
        settings = cls(
            database_url=os.getenv(
                "MONEY_PILOT_DATABASE_URL", "sqlite:///./money_pilot.db"
            ),
            environment=environment,
            jwt_secret=configured_secret or secrets.token_urlsafe(48),
            access_token_minutes=int(
                os.getenv("MONEY_PILOT_ACCESS_TOKEN_MINUTES", "15")
            ),
            refresh_token_days=int(os.getenv("MONEY_PILOT_REFRESH_TOKEN_DAYS", "30")),
        )
        settings.validate()
        return settings

    def validate(self) -> None:
        if self.access_token_minutes <= 0 or self.refresh_token_days <= 0:
            raise ValueError("token lifetimes must be positive")
        if not self.jwt_secret:
            raise ValueError("MONEY_PILOT_JWT_SECRET must not be empty")
        if self.environment.lower() in {"production", "prod"} and (
            len(self.jwt_secret) < 32
            or self.jwt_secret.upper().startswith(("CHANGE_ME", "YOUR_"))
        ):
            raise ValueError(
                "production requires a non-placeholder MONEY_PILOT_JWT_SECRET "
                "with at least 32 characters"
            )
