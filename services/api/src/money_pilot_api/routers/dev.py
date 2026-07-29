from __future__ import annotations

from datetime import timedelta

from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import Account, Bill, Budget, Category, Goal, User, utc_now
from ..routers.auth import seed_default_categories
from ..schemas import DemoSeedRead, TransactionCreate
from ..security import hash_password
from ..services import create_transaction

router = APIRouter(prefix="/dev", tags=["development"])

DEMO_EMAIL = "demo@moneypilot.dev"
DEMO_PASSWORD = "DemoMoneyPilot123!"


@router.post("/seed-demo", response_model=DemoSeedRead)
def seed_demo(
    request: Request,
    db: Session = Depends(get_db),
) -> DemoSeedRead:
    if request.app.state.settings.environment.lower() in {"production", "prod"}:
        raise HTTPException(status_code=404, detail="Not found")
    existing = db.scalar(select(User).where(User.email == DEMO_EMAIL))
    if existing is not None:
        return DemoSeedRead(
            email=DEMO_EMAIL,
            password=DEMO_PASSWORD,
            user_id=existing.id,
            seeded=False,
        )
    user = User(
        email=DEMO_EMAIL,
        password_hash=hash_password(DEMO_PASSWORD),
        display_name="Demo User",
        currency="USD",
    )
    db.add(user)
    db.flush()
    seed_default_categories(db, user.id)
    db.flush()
    categories = {
        category.name: category
        for category in db.scalars(
            select(Category).where(Category.user_id == user.id)
        ).all()
    }
    account = Account(
        user_id=user.id,
        name="Everyday Checking",
        account_type="checking",
        currency="USD",
        balance_minor=0,
        available_balance_minor=0,
    )
    db.add(account)
    db.flush()
    now = utc_now()
    create_transaction(
        db,
        user.id,
        TransactionCreate(
            transaction_type="income",
            amount_minor=250_000,
            currency="USD",
            occurred_at=now - timedelta(days=10),
            account_id=account.id,
            category_id=categories["Salary"].id,
            description="Monthly salary",
        ),
    )
    create_transaction(
        db,
        user.id,
        TransactionCreate(
            transaction_type="expense",
            amount_minor=42_500,
            currency="USD",
            occurred_at=now - timedelta(days=3),
            account_id=account.id,
            category_id=categories["Groceries"].id,
            merchant="Fresh Market",
        ),
    )
    today = now.date()
    db.add_all(
        [
            Budget(
                user_id=user.id,
                name="Monthly essentials",
                category_id=None,
                period_start=today,
                period_end=today + timedelta(days=29),
                planned_minor=120_000,
            ),
            Bill(
                user_id=user.id,
                name="Rent",
                amount_minor=80_000,
                currency="USD",
                due_date=today + timedelta(days=7),
                recurrence="monthly",
                account_id=account.id,
                category_id=categories["Housing"].id,
            ),
            Goal(
                user_id=user.id,
                name="Emergency fund",
                target_minor=600_000,
                current_minor=125_000,
                currency="USD",
                target_date=today + timedelta(days=365),
                linked_account_id=account.id,
                priority=1,
            ),
        ]
    )
    db.commit()
    return DemoSeedRead(
        email=DEMO_EMAIL,
        password=DEMO_PASSWORD,
        user_id=user.id,
        seeded=True,
    )
