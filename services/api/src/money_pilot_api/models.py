from __future__ import annotations

import uuid
from datetime import date, datetime, timezone
from typing import Any

from sqlalchemy import (
    JSON,
    BigInteger,
    Boolean,
    Date,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column

from .database import Base


def uuid_string() -> str:
    return str(uuid.uuid4())


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


class TimestampVersionMixin:
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, onupdate=utc_now, nullable=False
    )
    version: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=uuid_string)
    email: Mapped[str] = mapped_column(String(320), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    display_name: Mapped[str] = mapped_column(String(100))
    currency: Mapped[str] = mapped_column(String(3), default="USD")
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, onupdate=utc_now, nullable=False
    )


class UserSession(Base):
    __tablename__ = "sessions"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=uuid_string)
    user_id: Mapped[str] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    refresh_jti_hash: Mapped[str] = mapped_column(String(64))
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, nullable=False
    )


class Account(TimestampVersionMixin, Base):
    __tablename__ = "accounts"
    __table_args__ = (Index("ix_accounts_user_active", "user_id", "deleted_at"),)

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=uuid_string)
    user_id: Mapped[str] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    name: Mapped[str] = mapped_column(String(100))
    account_type: Mapped[str] = mapped_column(String(30))
    currency: Mapped[str] = mapped_column(String(3))
    balance_minor: Mapped[int] = mapped_column(BigInteger, default=0)
    available_balance_minor: Mapped[int] = mapped_column(BigInteger, default=0)
    include_in_net_worth: Mapped[bool] = mapped_column(Boolean, default=True)
    include_in_safe_to_spend: Mapped[bool] = mapped_column(Boolean, default=True)
    archived: Mapped[bool] = mapped_column(Boolean, default=False)
    notes: Mapped[str | None] = mapped_column(Text)


class Category(TimestampVersionMixin, Base):
    __tablename__ = "categories"
    __table_args__ = (
        UniqueConstraint("user_id", "name", name="uq_category_user_name"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=uuid_string)
    user_id: Mapped[str] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    name: Mapped[str] = mapped_column(String(80))
    kind: Mapped[str] = mapped_column(String(20))
    parent_id: Mapped[str | None] = mapped_column(
        ForeignKey("categories.id", ondelete="SET NULL")
    )
    archived: Mapped[bool] = mapped_column(Boolean, default=False)


class Transaction(TimestampVersionMixin, Base):
    __tablename__ = "transactions"
    __table_args__ = (
        Index("ix_transactions_user_date", "user_id", "occurred_at"),
        Index("ix_transactions_user_account", "user_id", "account_id"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=uuid_string)
    user_id: Mapped[str] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    transaction_type: Mapped[str] = mapped_column(String(30))
    amount_minor: Mapped[int] = mapped_column(BigInteger)
    currency: Mapped[str] = mapped_column(String(3))
    occurred_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    account_id: Mapped[str] = mapped_column(ForeignKey("accounts.id"), index=True)
    destination_account_id: Mapped[str | None] = mapped_column(
        ForeignKey("accounts.id")
    )
    category_id: Mapped[str | None] = mapped_column(
        ForeignKey("categories.id", ondelete="SET NULL")
    )
    merchant: Mapped[str | None] = mapped_column(String(120))
    description: Mapped[str | None] = mapped_column(String(255))
    notes: Mapped[str | None] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(20), default="cleared")


class Budget(TimestampVersionMixin, Base):
    __tablename__ = "budgets"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=uuid_string)
    user_id: Mapped[str] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    name: Mapped[str] = mapped_column(String(100))
    category_id: Mapped[str | None] = mapped_column(
        ForeignKey("categories.id", ondelete="SET NULL")
    )
    period_start: Mapped[date] = mapped_column(Date)
    period_end: Mapped[date] = mapped_column(Date)
    planned_minor: Mapped[int] = mapped_column(BigInteger)
    rollover_mode: Mapped[str] = mapped_column(String(30), default="none")


class Bill(TimestampVersionMixin, Base):
    __tablename__ = "bills"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=uuid_string)
    user_id: Mapped[str] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    name: Mapped[str] = mapped_column(String(100))
    amount_minor: Mapped[int] = mapped_column(BigInteger)
    currency: Mapped[str] = mapped_column(String(3))
    due_date: Mapped[date] = mapped_column(Date, index=True)
    recurrence: Mapped[str] = mapped_column(String(30), default="none")
    account_id: Mapped[str | None] = mapped_column(
        ForeignKey("accounts.id", ondelete="SET NULL")
    )
    category_id: Mapped[str | None] = mapped_column(
        ForeignKey("categories.id", ondelete="SET NULL")
    )
    is_paid: Mapped[bool] = mapped_column(Boolean, default=False)
    notes: Mapped[str | None] = mapped_column(Text)


class Goal(TimestampVersionMixin, Base):
    __tablename__ = "goals"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=uuid_string)
    user_id: Mapped[str] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    name: Mapped[str] = mapped_column(String(100))
    target_minor: Mapped[int] = mapped_column(BigInteger)
    current_minor: Mapped[int] = mapped_column(BigInteger, default=0)
    currency: Mapped[str] = mapped_column(String(3))
    target_date: Mapped[date | None] = mapped_column(Date)
    linked_account_id: Mapped[str | None] = mapped_column(
        ForeignKey("accounts.id", ondelete="SET NULL")
    )
    priority: Mapped[int] = mapped_column(Integer, default=3)


class SyncOperation(Base):
    __tablename__ = "sync_operations"
    __table_args__ = (
        UniqueConstraint(
            "user_id", "client_operation_id", name="uq_sync_user_client_operation"
        ),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=uuid_string)
    user_id: Mapped[str] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    client_operation_id: Mapped[str] = mapped_column(String(100))
    entity_type: Mapped[str] = mapped_column(String(40))
    entity_id: Mapped[str | None] = mapped_column(String(36))
    operation: Mapped[str] = mapped_column(String(20))
    base_version: Mapped[int | None] = mapped_column(Integer)
    payload: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    result: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    status: Mapped[str] = mapped_column(String(20))
    server_version: Mapped[int | None] = mapped_column(Integer)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, nullable=False
    )


class AIActionProposal(Base):
    __tablename__ = "ai_action_proposals"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=uuid_string)
    user_id: Mapped[str] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    action_type: Mapped[str] = mapped_column(String(50))
    payload: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    payload_hash: Mapped[str] = mapped_column(String(64))
    explanation: Mapped[str] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(20), default="pending")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utc_now, nullable=False
    )
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
