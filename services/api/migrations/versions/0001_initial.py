"""Create the MoneyPilot milestone-one schema.

Revision ID: 0001_initial
Revises: None
Create Date: 2026-07-15
"""

from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "0001_initial"
down_revision: str | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def _owned_timestamps() -> list[sa.Column]:
    return [
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("version", sa.Integer(), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
    ]


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("email", sa.String(length=320), nullable=False),
        sa.Column("password_hash", sa.String(length=255), nullable=False),
        sa.Column("display_name", sa.String(length=100), nullable=False),
        sa.Column("currency", sa.String(length=3), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_users_email", "users", ["email"], unique=True)

    op.create_table(
        "sessions",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("user_id", sa.String(length=36), nullable=False),
        sa.Column("refresh_jti_hash", sa.String(length=64), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_sessions_user_id", "sessions", ["user_id"], unique=False)

    op.create_table(
        "accounts",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("user_id", sa.String(length=36), nullable=False),
        sa.Column("name", sa.String(length=100), nullable=False),
        sa.Column("account_type", sa.String(length=30), nullable=False),
        sa.Column("currency", sa.String(length=3), nullable=False),
        sa.Column("balance_minor", sa.BigInteger(), nullable=False),
        sa.Column("available_balance_minor", sa.BigInteger(), nullable=False),
        sa.Column("include_in_net_worth", sa.Boolean(), nullable=False),
        sa.Column("include_in_safe_to_spend", sa.Boolean(), nullable=False),
        sa.Column("archived", sa.Boolean(), nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        *_owned_timestamps(),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_accounts_user_id", "accounts", ["user_id"], unique=False)
    op.create_index(
        "ix_accounts_user_active", "accounts", ["user_id", "deleted_at"], unique=False
    )

    op.create_table(
        "categories",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("user_id", sa.String(length=36), nullable=False),
        sa.Column("name", sa.String(length=80), nullable=False),
        sa.Column("kind", sa.String(length=20), nullable=False),
        sa.Column("parent_id", sa.String(length=36), nullable=True),
        sa.Column("archived", sa.Boolean(), nullable=False),
        *_owned_timestamps(),
        sa.ForeignKeyConstraint(["parent_id"], ["categories.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id", "name", name="uq_category_user_name"),
    )
    op.create_index("ix_categories_user_id", "categories", ["user_id"], unique=False)

    op.create_table(
        "transactions",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("user_id", sa.String(length=36), nullable=False),
        sa.Column("transaction_type", sa.String(length=30), nullable=False),
        sa.Column("amount_minor", sa.BigInteger(), nullable=False),
        sa.Column("currency", sa.String(length=3), nullable=False),
        sa.Column("occurred_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("account_id", sa.String(length=36), nullable=False),
        sa.Column("destination_account_id", sa.String(length=36), nullable=True),
        sa.Column("category_id", sa.String(length=36), nullable=True),
        sa.Column("merchant", sa.String(length=120), nullable=True),
        sa.Column("description", sa.String(length=255), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("status", sa.String(length=20), nullable=False),
        *_owned_timestamps(),
        sa.ForeignKeyConstraint(["account_id"], ["accounts.id"]),
        sa.ForeignKeyConstraint(
            ["category_id"], ["categories.id"], ondelete="SET NULL"
        ),
        sa.ForeignKeyConstraint(["destination_account_id"], ["accounts.id"]),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_transactions_account_id", "transactions", ["account_id"], unique=False
    )
    op.create_index(
        "ix_transactions_occurred_at", "transactions", ["occurred_at"], unique=False
    )
    op.create_index(
        "ix_transactions_user_id", "transactions", ["user_id"], unique=False
    )
    op.create_index(
        "ix_transactions_user_account",
        "transactions",
        ["user_id", "account_id"],
        unique=False,
    )
    op.create_index(
        "ix_transactions_user_date",
        "transactions",
        ["user_id", "occurred_at"],
        unique=False,
    )

    op.create_table(
        "budgets",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("user_id", sa.String(length=36), nullable=False),
        sa.Column("name", sa.String(length=100), nullable=False),
        sa.Column("category_id", sa.String(length=36), nullable=True),
        sa.Column("period_start", sa.Date(), nullable=False),
        sa.Column("period_end", sa.Date(), nullable=False),
        sa.Column("planned_minor", sa.BigInteger(), nullable=False),
        sa.Column("rollover_mode", sa.String(length=30), nullable=False),
        *_owned_timestamps(),
        sa.ForeignKeyConstraint(
            ["category_id"], ["categories.id"], ondelete="SET NULL"
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_budgets_user_id", "budgets", ["user_id"], unique=False)

    op.create_table(
        "bills",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("user_id", sa.String(length=36), nullable=False),
        sa.Column("name", sa.String(length=100), nullable=False),
        sa.Column("amount_minor", sa.BigInteger(), nullable=False),
        sa.Column("currency", sa.String(length=3), nullable=False),
        sa.Column("due_date", sa.Date(), nullable=False),
        sa.Column("recurrence", sa.String(length=30), nullable=False),
        sa.Column("account_id", sa.String(length=36), nullable=True),
        sa.Column("category_id", sa.String(length=36), nullable=True),
        sa.Column("is_paid", sa.Boolean(), nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        *_owned_timestamps(),
        sa.ForeignKeyConstraint(["account_id"], ["accounts.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(
            ["category_id"], ["categories.id"], ondelete="SET NULL"
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_bills_due_date", "bills", ["due_date"], unique=False)
    op.create_index("ix_bills_user_id", "bills", ["user_id"], unique=False)

    op.create_table(
        "goals",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("user_id", sa.String(length=36), nullable=False),
        sa.Column("name", sa.String(length=100), nullable=False),
        sa.Column("target_minor", sa.BigInteger(), nullable=False),
        sa.Column("current_minor", sa.BigInteger(), nullable=False),
        sa.Column("currency", sa.String(length=3), nullable=False),
        sa.Column("target_date", sa.Date(), nullable=True),
        sa.Column("linked_account_id", sa.String(length=36), nullable=True),
        sa.Column("priority", sa.Integer(), nullable=False),
        *_owned_timestamps(),
        sa.ForeignKeyConstraint(
            ["linked_account_id"], ["accounts.id"], ondelete="SET NULL"
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_goals_user_id", "goals", ["user_id"], unique=False)

    op.create_table(
        "sync_operations",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("user_id", sa.String(length=36), nullable=False),
        sa.Column("client_operation_id", sa.String(length=100), nullable=False),
        sa.Column("entity_type", sa.String(length=40), nullable=False),
        sa.Column("entity_id", sa.String(length=36), nullable=True),
        sa.Column("operation", sa.String(length=20), nullable=False),
        sa.Column("base_version", sa.Integer(), nullable=True),
        sa.Column("payload", sa.JSON(), nullable=False),
        sa.Column("result", sa.JSON(), nullable=False),
        sa.Column("status", sa.String(length=20), nullable=False),
        sa.Column("server_version", sa.Integer(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "user_id",
            "client_operation_id",
            name="uq_sync_user_client_operation",
        ),
    )
    op.create_index(
        "ix_sync_operations_user_id", "sync_operations", ["user_id"], unique=False
    )

    op.create_table(
        "ai_action_proposals",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("user_id", sa.String(length=36), nullable=False),
        sa.Column("action_type", sa.String(length=50), nullable=False),
        sa.Column("payload", sa.JSON(), nullable=False),
        sa.Column("payload_hash", sa.String(length=64), nullable=False),
        sa.Column("explanation", sa.Text(), nullable=False),
        sa.Column("status", sa.String(length=20), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("resolved_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_ai_action_proposals_user_id",
        "ai_action_proposals",
        ["user_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_table("ai_action_proposals")
    op.drop_table("sync_operations")
    op.drop_table("goals")
    op.drop_table("bills")
    op.drop_table("budgets")
    op.drop_table("transactions")
    op.drop_table("categories")
    op.drop_table("accounts")
    op.drop_table("sessions")
    op.drop_table("users")
