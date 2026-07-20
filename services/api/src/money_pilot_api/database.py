from __future__ import annotations

from collections.abc import Generator

from fastapi import Request
from sqlalchemy import Engine, create_engine, event
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker
from sqlalchemy.pool import StaticPool


class Base(DeclarativeBase):
    pass


class Database:
    def __init__(self, url: str) -> None:
        engine_kwargs: dict[str, object] = {"pool_pre_ping": True}
        if url.startswith("sqlite"):
            engine_kwargs["connect_args"] = {"check_same_thread": False}
            if url in {"sqlite://", "sqlite:///:memory:"}:
                engine_kwargs["poolclass"] = StaticPool
        self.engine: Engine = create_engine(url, **engine_kwargs)
        if url.startswith("sqlite"):
            event.listen(self.engine, "connect", self._enable_sqlite_foreign_keys)
        self.session_factory = sessionmaker(
            bind=self.engine,
            class_=Session,
            autoflush=False,
            expire_on_commit=False,
        )

    @staticmethod
    def _enable_sqlite_foreign_keys(dbapi_connection: object, _: object) -> None:
        cursor = dbapi_connection.cursor()  # type: ignore[attr-defined]
        cursor.execute("PRAGMA foreign_keys=ON")
        cursor.close()

    def create_schema(self) -> None:
        Base.metadata.create_all(self.engine)

    def dispose(self) -> None:
        self.engine.dispose()


def get_db(request: Request) -> Generator[Session, None, None]:
    database: Database = request.app.state.database
    session = database.session_factory()
    try:
        yield session
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()
