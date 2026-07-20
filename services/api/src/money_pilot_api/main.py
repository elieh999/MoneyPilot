from __future__ import annotations

import uuid
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from .config import Settings
from .database import Database
from .routers import (
    accounts,
    ai,
    auth,
    categories,
    dashboard,
    dev,
    planning,
    sync,
    transactions,
)


def create_app(settings: Settings | None = None) -> FastAPI:
    resolved_settings = settings or Settings.from_env()
    resolved_settings.validate()
    database = Database(resolved_settings.database_url)

    @asynccontextmanager
    async def lifespan(_: FastAPI):
        database.create_schema()
        yield
        database.dispose()

    app = FastAPI(
        title="MoneyPilot API",
        version="0.1.0",
        description=(
            "Offline-sync-ready personal finance API. All monetary values are "
            "integer minor units."
        ),
        lifespan=lifespan,
    )
    app.state.settings = resolved_settings
    app.state.database = database
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[],
        allow_credentials=False,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    @app.middleware("http")
    async def correlation_id(request: Request, call_next):
        request_id = request.headers.get("X-Request-ID") or str(uuid.uuid4())
        request.state.request_id = request_id
        response = await call_next(request)
        response.headers["X-Request-ID"] = request_id
        return response

    @app.get("/", tags=["system"])
    def root() -> dict[str, str]:
        return {"name": "MoneyPilot API", "version": "0.1.0"}

    @app.get("/health/live", tags=["system"])
    def liveness() -> dict[str, str]:
        return {"status": "ok"}

    @app.get("/health/ready", tags=["system"])
    def readiness() -> dict[str, str]:
        with database.session_factory() as db:
            db.execute(text("SELECT 1"))
        return {"status": "ready"}

    api_prefix = "/api/v1"
    app.include_router(auth.router, prefix=api_prefix)
    app.include_router(accounts.router, prefix=api_prefix)
    app.include_router(categories.router, prefix=api_prefix)
    app.include_router(transactions.router, prefix=api_prefix)
    app.include_router(planning.router, prefix=api_prefix)
    app.include_router(dashboard.router, prefix=api_prefix)
    app.include_router(sync.router, prefix=api_prefix)
    app.include_router(ai.router, prefix=api_prefix)
    app.include_router(dev.router, prefix=api_prefix)
    return app


app = create_app()
