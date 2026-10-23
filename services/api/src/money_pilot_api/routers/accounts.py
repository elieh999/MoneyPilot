from __future__ import annotations

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..database import get_db
from ..dependencies import get_current_user
from ..models import Account, User, utc_now
from ..schemas import AccountCreate, AccountRead, AccountUpdate, MessageResponse
from ..services import ensure_version, owned_or_404

router = APIRouter(prefix="/accounts", tags=["accounts"])


@router.post("", response_model=AccountRead, status_code=status.HTTP_201_CREATED)
def create_account(
    payload: AccountCreate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Account:
    account = Account(
        user_id=user.id,
        name=payload.name.strip(),
        account_type=payload.account_type,
        currency=payload.currency,
        balance_minor=payload.balance_minor,
        available_balance_minor=(
            payload.balance_minor
            if payload.available_balance_minor is None
            else payload.available_balance_minor
        ),
        include_in_net_worth=payload.include_in_net_worth,
        include_in_safe_to_spend=payload.include_in_safe_to_spend,
        archived=payload.archived,
        notes=payload.notes,
    )
    db.add(account)
    db.commit()
    return account


@router.get("", response_model=list[AccountRead])
def list_accounts(
    include_archived: bool = False,
    limit: int = Query(default=100, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[Account]:
    query = select(Account).where(
        Account.user_id == user.id, Account.deleted_at.is_(None)
    )
    if not include_archived:
        query = query.where(Account.archived.is_(False))
    return list(
        db.scalars(query.order_by(Account.created_at).offset(offset).limit(limit)).all()
    )


@router.get("/{account_id}", response_model=AccountRead)
def get_account(
    account_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Account:
    return owned_or_404(db, Account, account_id, user.id)


@router.patch("/{account_id}", response_model=AccountRead)
def update_account(
    account_id: str,
    payload: AccountUpdate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Account:
    account = owned_or_404(db, Account, account_id, user.id)
    ensure_version(account, payload.version)
    for field_name, value in payload.model_dump(
        exclude_unset=True, exclude={"version"}
    ).items():
        setattr(account, field_name, value)
    account.version += 1
    db.commit()
    return account


@router.delete("/{account_id}", response_model=MessageResponse)
def delete_account(
    account_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    account = owned_or_404(db, Account, account_id, user.id)
    account.deleted_at = utc_now()
    account.archived = True
    account.version += 1
    db.commit()
    return MessageResponse(message="Account archived and removed from active views")
