from __future__ import annotations

from datetime import datetime

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..database import get_db
from ..dependencies import get_current_user
from ..models import Transaction, User
from ..schemas import (
    MessageResponse,
    TransactionCreate,
    TransactionRead,
    TransactionUpdate,
)
from ..services import (
    create_transaction,
    delete_transaction,
    owned_or_404,
    restore_transaction,
    update_transaction,
)


router = APIRouter(prefix="/transactions", tags=["transactions"])


@router.post("", response_model=TransactionRead, status_code=status.HTTP_201_CREATED)
def create_transaction_route(
    payload: TransactionCreate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Transaction:
    transaction = create_transaction(db, user.id, payload)
    db.commit()
    return transaction


@router.get("", response_model=list[TransactionRead])
def list_transactions(
    account_id: str | None = None,
    category_id: str | None = None,
    transaction_type: str | None = None,
    date_from: datetime | None = None,
    date_to: datetime | None = None,
    include_deleted: bool = False,
    limit: int = Query(default=100, ge=1, le=500),
    offset: int = Query(default=0, ge=0),
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[Transaction]:
    query = select(Transaction).where(Transaction.user_id == user.id)
    if not include_deleted:
        query = query.where(Transaction.deleted_at.is_(None))
    if account_id:
        query = query.where(Transaction.account_id == account_id)
    if category_id:
        query = query.where(Transaction.category_id == category_id)
    if transaction_type:
        query = query.where(Transaction.transaction_type == transaction_type)
    if date_from:
        query = query.where(Transaction.occurred_at >= date_from)
    if date_to:
        query = query.where(Transaction.occurred_at <= date_to)
    return list(
        db.scalars(
            query.order_by(Transaction.occurred_at.desc()).offset(offset).limit(limit)
        ).all()
    )


@router.get("/{transaction_id}", response_model=TransactionRead)
def get_transaction(
    transaction_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Transaction:
    return owned_or_404(db, Transaction, transaction_id, user.id)


@router.patch("/{transaction_id}", response_model=TransactionRead)
def update_transaction_route(
    transaction_id: str,
    payload: TransactionUpdate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Transaction:
    transaction = owned_or_404(db, Transaction, transaction_id, user.id)
    update_transaction(db, transaction, payload)
    db.commit()
    return transaction


@router.delete("/{transaction_id}", response_model=MessageResponse)
def delete_transaction_route(
    transaction_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    transaction = owned_or_404(db, Transaction, transaction_id, user.id)
    delete_transaction(db, transaction)
    db.commit()
    return MessageResponse(message="Transaction moved to trash and balances restored")


@router.post("/{transaction_id}/restore", response_model=TransactionRead)
def restore_transaction_route(
    transaction_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Transaction:
    transaction = owned_or_404(
        db, Transaction, transaction_id, user.id, include_deleted=True
    )
    restore_transaction(db, transaction)
    db.commit()
    return transaction
