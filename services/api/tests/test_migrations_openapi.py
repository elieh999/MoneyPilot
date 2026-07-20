from __future__ import annotations

import json
from pathlib import Path

from alembic import command
from alembic.config import Config
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, inspect


API_ROOT = Path(__file__).resolve().parents[1]


def test_initial_alembic_migration_up_and_down(tmp_path: Path) -> None:
    database_path = tmp_path / "migration.db"
    config = Config(str(API_ROOT / "alembic.ini"))
    config.set_main_option("script_location", str(API_ROOT / "migrations"))
    config.set_main_option("sqlalchemy.url", f"sqlite:///{database_path.as_posix()}")
    command.upgrade(config, "head")
    engine = create_engine(f"sqlite:///{database_path.as_posix()}")
    expected = {
        "users",
        "sessions",
        "accounts",
        "categories",
        "transactions",
        "budgets",
        "bills",
        "goals",
        "sync_operations",
        "ai_action_proposals",
        "alembic_version",
    }
    assert set(inspect(engine).get_table_names()) == expected
    engine.dispose()
    command.downgrade(config, "base")
    engine = create_engine(f"sqlite:///{database_path.as_posix()}")
    assert set(inspect(engine).get_table_names()) <= {"alembic_version"}
    engine.dispose()


def test_checked_openapi_matches_application(client: TestClient) -> None:
    checked_schema = json.loads((API_ROOT / "openapi.json").read_text(encoding="utf-8"))
    assert checked_schema == client.app.openapi()
