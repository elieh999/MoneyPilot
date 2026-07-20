from __future__ import annotations

from datetime import date, datetime, timedelta, timezone
from typing import Any, TypeVar
from uuid import UUID

from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from money_pilot_financial_core import (
    SafeToSpendInput,
    allowance_for_period,
    calculate_dashboard_totals,
    calculate_safe_to_spend,
)

from . import models
from .schemas import TransactionCreate, TransactionUpdate


OwnedModel = TypeVar(
    "OwnedModel",
    models.Account,
    models.Category,
    models.Transaction,
    models.Budget,
    models.Bill,
    models.Goal,
    models.AIActionProposal,
)


ACCOUNT_CREDIT_TYPES = {"income", "refund", "reimbursement", "account_adjustment"}
INCOME_TYPES = {"income"}
EXPENSE_TYPES = {"expense", "debt_payment", "investment_contribution"}
EXPENSE_OFFSET_TYPES = {"refund", "reimbursement"}


def owned_or_404(
    db: Session,
    model_type: type[OwnedModel],
    entity_id: str | UUID,
    user_id: str,
    *,
    include_deleted: bool = False,
) -> OwnedModel:
    entity = db.get(model_type, str(entity_id))
    if entity is None or entity.user_id != user_id:
        raise HTTPException(status_code=404, detail=f"{model_type.__name__} not found")
    if (
        not include_deleted
        and hasattr(entity, "deleted_at")
        and entity.deleted_at is not None
    ):
        raise HTTPException(status_code=404, detail=f"{model_type.__name__} not found")
    return entity


def ensure_version(entity: Any, expected_version: int | None) -> None:
    if expected_version is not None and entity.version != expected_version:
        raise HTTPException(
            status_code=409,
            detail={
                "message": "The record changed on another device",
                "expected_version": expected_version,
                "server_version": entity.version,
            },
        )


def validate_optional_links(
    db: Session,
    user_id: str,
    *,
    account_id: str | UUID | None = None,
    category_id: str | UUID | None = None,
) -> None:
    if account_id is not None:
        owned_or_404(db, models.Account, account_id, user_id)
    if category_id is not None:
        owned_or_404(db, models.Category, category_id, user_id)


def _account_delta(transaction_type: str, amount_minor: int) -> int:
    if transaction_type in ACCOUNT_CREDIT_TYPES:
        return amount_minor
    if transaction_type in EXPENSE_TYPES or transaction_type == "transfer":
        return -amount_minor
    raise HTTPException(status_code=422, detail="Unsupported transaction type")


def apply_transaction_balances(
    db: Session, transaction: models.Transaction, *, multiplier: int
) -> None:
    source = owned_or_404(
        db, models.Account, transaction.account_id, transaction.user_id
    )
    if source.archived:
        raise HTTPException(
            status_code=409, detail="Archived accounts cannot be changed"
        )
    if source.currency != transaction.currency:
        raise HTTPException(
            status_code=422,
            detail="Transaction currency must match the source account",
        )
    destination = None
    if transaction.transaction_type == "transfer":
        if transaction.destination_account_id is None:
            raise HTTPException(
                status_code=422, detail="Transfers require a destination account"
            )
        destination = owned_or_404(
            db,
            models.Account,
            transaction.destination_account_id,
            transaction.user_id,
        )
        if destination.archived:
            raise HTTPException(
                status_code=409, detail="Archived accounts cannot be changed"
            )
        if destination.currency != transaction.currency:
            raise HTTPException(
                status_code=422,
                detail="Cross-currency transfers require an explicit conversion workflow",
            )

    # Mutate balances only after every source/destination ownership, status, and
    # currency check has passed. The request dependency also rolls back any
    # exception before commit.
    source_delta = (
        _account_delta(transaction.transaction_type, transaction.amount_minor)
        * multiplier
    )
    source.available_balance_minor += source_delta
    if transaction.status == "cleared":
        source.balance_minor += source_delta
    source.version += 1

    if destination is not None:
        destination_delta = transaction.amount_minor * multiplier
        destination.available_balance_minor += destination_delta
        if transaction.status == "cleared":
            destination.balance_minor += destination_delta
        destination.version += 1


def create_transaction(
    db: Session,
    user_id: str,
    data: TransactionCreate,
    *,
    entity_id: str | None = None,
) -> models.Transaction:
    validate_optional_links(
        db, user_id, account_id=data.account_id, category_id=data.category_id
    )
    transaction = models.Transaction(
        id=entity_id or models.uuid_string(),
        user_id=user_id,
        **data.model_dump(mode="python"),
    )
    transaction.account_id = str(data.account_id)
    transaction.destination_account_id = (
        str(data.destination_account_id) if data.destination_account_id else None
    )
    transaction.category_id = str(data.category_id) if data.category_id else None
    db.add(transaction)
    apply_transaction_balances(db, transaction, multiplier=1)
    db.flush()
    return transaction


def update_transaction(
    db: Session,
    transaction: models.Transaction,
    data: TransactionUpdate,
) -> models.Transaction:
    ensure_version(transaction, data.version)
    apply_transaction_balances(db, transaction, multiplier=-1)
    current: dict[str, Any] = {
        "transaction_type": transaction.transaction_type,
        "amount_minor": transaction.amount_minor,
        "currency": transaction.currency,
        "occurred_at": transaction.occurred_at,
        "account_id": transaction.account_id,
        "destination_account_id": transaction.destination_account_id,
        "category_id": transaction.category_id,
        "merchant": transaction.merchant,
        "description": transaction.description,
        "notes": transaction.notes,
        "status": transaction.status,
    }
    changes = data.model_dump(exclude_unset=True, exclude={"version"})
    current.update(changes)
    validated = TransactionCreate.model_validate(current)
    validate_optional_links(
        db,
        transaction.user_id,
        account_id=validated.account_id,
        category_id=validated.category_id,
    )
    for key, value in validated.model_dump(mode="python").items():
        if key.endswith("_id") and value is not None:
            value = str(value)
        setattr(transaction, key, value)
    transaction.version += 1
    apply_transaction_balances(db, transaction, multiplier=1)
    db.flush()
    return transaction


def delete_transaction(db: Session, transaction: models.Transaction) -> None:
    if transaction.deleted_at is None:
        apply_transaction_balances(db, transaction, multiplier=-1)
        transaction.deleted_at = models.utc_now()
        transaction.version += 1
        db.flush()


def restore_transaction(db: Session, transaction: models.Transaction) -> None:
    if transaction.deleted_at is not None:
        transaction.deleted_at = None
        transaction.version += 1
        apply_transaction_balances(db, transaction, multiplier=1)
        db.flush()


def financial_summary(db: Session, user: models.User) -> dict[str, Any]:
    accounts = db.scalars(
        select(models.Account).where(
            models.Account.user_id == user.id,
            models.Account.deleted_at.is_(None),
            models.Account.archived.is_(False),
        )
    ).all()
    included_accounts = [
        account
        for account in accounts
        if account.currency == user.currency and account.include_in_safe_to_spend
    ]
    excluded_currency_count = sum(
        1 for account in accounts if account.currency != user.currency
    )
    total_available = sum(
        account.available_balance_minor for account in included_accounts
    )

    now = models.utc_now()
    month_start = datetime(now.year, now.month, 1, tzinfo=timezone.utc)
    transactions = db.scalars(
        select(models.Transaction).where(
            models.Transaction.user_id == user.id,
            models.Transaction.deleted_at.is_(None),
            models.Transaction.occurred_at >= month_start,
            models.Transaction.currency == user.currency,
        )
    ).all()
    gross_expenses = sum(
        t.amount_minor for t in transactions if t.transaction_type in EXPENSE_TYPES
    )
    expense_offsets = sum(
        t.amount_minor
        for t in transactions
        if t.transaction_type in EXPENSE_OFFSET_TYPES
    )
    totals = calculate_dashboard_totals(
        [t.amount_minor for t in transactions if t.transaction_type in INCOME_TYPES],
        [max(gross_expenses - expense_offsets, 0)],
    )
    today = models.utc_now().date()
    cutoff = today + timedelta(days=30)
    upcoming_bills = db.scalars(
        select(models.Bill).where(
            models.Bill.user_id == user.id,
            models.Bill.deleted_at.is_(None),
            models.Bill.is_paid.is_(False),
            models.Bill.currency == user.currency,
            models.Bill.due_date >= today,
            models.Bill.due_date <= cutoff,
        )
    ).all()
    bill_total = sum(bill.amount_minor for bill in upcoming_bills)
    goals = db.scalars(
        select(models.Goal).where(
            models.Goal.user_id == user.id,
            models.Goal.deleted_at.is_(None),
            models.Goal.currency == user.currency,
        )
    ).all()
    safe = calculate_safe_to_spend(
        SafeToSpendInput(
            available_balance_minor=total_available,
            upcoming_required_bills_minor=bill_total,
        )
    )
    return {
        "currency": user.currency,
        "total_available_balance_minor": total_available,
        "current_month_income_minor": totals.income_minor,
        "current_month_expenses_minor": totals.expenses_minor,
        "net_cash_flow_minor": totals.net_cash_flow_minor,
        "savings_rate_basis_points": totals.savings_rate_basis_points,
        "upcoming_bills_minor": bill_total,
        "upcoming_bill_count": len(upcoming_bills),
        "goal_saved_minor": sum(goal.current_minor for goal in goals),
        "goal_target_minor": sum(goal.target_minor for goal in goals),
        "safe_to_spend_minor": safe.safe_to_spend_minor,
        "safe_to_spend_shortfall_minor": safe.shortfall_minor,
        "excluded_currency_account_count": excluded_currency_count,
    }


def safe_to_spend_summary(
    db: Session,
    user: models.User,
    *,
    until_date: date,
    confirmed_income_minor: int = 0,
    debt_minimum_payments_minor: int = 0,
    planned_savings_minor: int = 0,
    goal_contributions_minor: int = 0,
    emergency_reserve_minor: int = 0,
    credit_card_obligations_minor: int = 0,
    safety_buffer_minor: int = 0,
    known_one_time_expenses_minor: int = 0,
    forecast_uncertainty_buffer_minor: int = 0,
) -> dict[str, Any]:
    accounts = db.scalars(
        select(models.Account).where(
            models.Account.user_id == user.id,
            models.Account.deleted_at.is_(None),
            models.Account.archived.is_(False),
            models.Account.include_in_safe_to_spend.is_(True),
            models.Account.currency == user.currency,
        )
    ).all()
    available = sum(account.available_balance_minor for account in accounts)
    bills = db.scalars(
        select(models.Bill).where(
            models.Bill.user_id == user.id,
            models.Bill.deleted_at.is_(None),
            models.Bill.is_paid.is_(False),
            models.Bill.currency == user.currency,
            models.Bill.due_date >= models.utc_now().date(),
            models.Bill.due_date <= until_date,
        )
    ).all()
    result = calculate_safe_to_spend(
        SafeToSpendInput(
            available_balance_minor=available,
            # Available balances are already adjusted for both cleared and pending
            # local transactions, so pending outflows must not be subtracted twice.
            pending_outflows_minor=0,
            upcoming_required_bills_minor=sum(b.amount_minor for b in bills),
            debt_minimum_payments_minor=debt_minimum_payments_minor,
            planned_savings_minor=planned_savings_minor,
            goal_contributions_minor=goal_contributions_minor,
            confirmed_income_minor=confirmed_income_minor,
            emergency_reserve_minor=emergency_reserve_minor,
            credit_card_obligations_minor=credit_card_obligations_minor,
            safety_buffer_minor=safety_buffer_minor,
            known_one_time_expenses_minor=known_one_time_expenses_minor,
            forecast_uncertainty_buffer_minor=forecast_uncertainty_buffer_minor,
        )
    )
    days = max((until_date - models.utc_now().date()).days, 1)
    return {
        "currency": user.currency,
        "until_date": until_date,
        "safe_to_spend_minor": result.safe_to_spend_minor,
        "raw_safe_to_spend_minor": result.raw_safe_to_spend_minor,
        "shortfall_minor": result.shortfall_minor,
        "minimum_untouched_minor": result.minimum_untouched_minor,
        "available_balance_minor": result.available_balance_minor,
        "confirmed_income_minor": result.confirmed_income_minor,
        "deductions": result.deductions,
        "daily_allowance_minor": allowance_for_period(result.safe_to_spend_minor, days),
        "explanation": [
            f"Start with {available} {user.currency} minor units in included available balances.",
            "Pending local transactions are already reflected in available balances.",
            f"Add {confirmed_income_minor} confirmed income minor units before the selected date.",
            f"Reserve {result.minimum_untouched_minor} minor units for bills, goals, savings, and buffers.",
            "A negative raw result is shown as a shortfall, never as spendable money.",
        ],
    }
