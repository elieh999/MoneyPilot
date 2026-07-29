from __future__ import annotations

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..database import get_db
from ..dependencies import get_current_user
from ..models import Bill, Budget, Goal, User, utc_now
from ..schemas import (
    BillCreate,
    BillRead,
    BillUpdate,
    BudgetCreate,
    BudgetRead,
    BudgetUpdate,
    GoalCreate,
    GoalRead,
    GoalUpdate,
    MessageResponse,
)
from ..services import ensure_version, owned_or_404, validate_optional_links

router = APIRouter(tags=["planning"])


@router.post("/budgets", response_model=BudgetRead, status_code=status.HTTP_201_CREATED)
def create_budget(
    payload: BudgetCreate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Budget:
    validate_optional_links(db, user.id, category_id=payload.category_id)
    budget = Budget(
        user_id=user.id,
        name=payload.name.strip(),
        category_id=str(payload.category_id) if payload.category_id else None,
        period_start=payload.period_start,
        period_end=payload.period_end,
        planned_minor=payload.planned_minor,
        rollover_mode=payload.rollover_mode,
    )
    db.add(budget)
    db.commit()
    return budget


@router.get("/budgets", response_model=list[BudgetRead])
def list_budgets(
    limit: int = Query(default=100, ge=1, le=200),
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[Budget]:
    return list(
        db.scalars(
            select(Budget)
            .where(Budget.user_id == user.id, Budget.deleted_at.is_(None))
            .order_by(Budget.period_start.desc())
            .limit(limit)
        ).all()
    )


@router.get("/budgets/{budget_id}", response_model=BudgetRead)
def get_budget(
    budget_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Budget:
    return owned_or_404(db, Budget, budget_id, user.id)


@router.patch("/budgets/{budget_id}", response_model=BudgetRead)
def update_budget(
    budget_id: str,
    payload: BudgetUpdate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Budget:
    budget = owned_or_404(db, Budget, budget_id, user.id)
    ensure_version(budget, payload.version)
    current = {
        "name": budget.name,
        "category_id": budget.category_id,
        "period_start": budget.period_start,
        "period_end": budget.period_end,
        "planned_minor": budget.planned_minor,
        "rollover_mode": budget.rollover_mode,
    }
    current.update(payload.model_dump(exclude_unset=True, exclude={"version"}))
    validated = BudgetCreate.model_validate(current)
    validate_optional_links(db, user.id, category_id=validated.category_id)
    for key, value in validated.model_dump(mode="python").items():
        if key == "category_id" and value is not None:
            value = str(value)
        setattr(budget, key, value)
    budget.version += 1
    db.commit()
    return budget


@router.delete("/budgets/{budget_id}", response_model=MessageResponse)
def delete_budget(
    budget_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    budget = owned_or_404(db, Budget, budget_id, user.id)
    budget.deleted_at = utc_now()
    budget.version += 1
    db.commit()
    return MessageResponse(message="Budget deleted")


@router.post("/bills", response_model=BillRead, status_code=status.HTTP_201_CREATED)
def create_bill(
    payload: BillCreate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Bill:
    validate_optional_links(
        db,
        user.id,
        account_id=payload.account_id,
        category_id=payload.category_id,
    )
    bill = Bill(
        user_id=user.id,
        name=payload.name.strip(),
        amount_minor=payload.amount_minor,
        currency=payload.currency,
        due_date=payload.due_date,
        recurrence=payload.recurrence,
        account_id=str(payload.account_id) if payload.account_id else None,
        category_id=str(payload.category_id) if payload.category_id else None,
        is_paid=payload.is_paid,
        notes=payload.notes,
    )
    db.add(bill)
    db.commit()
    return bill


@router.get("/bills", response_model=list[BillRead])
def list_bills(
    include_paid: bool = True,
    limit: int = Query(default=100, ge=1, le=200),
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[Bill]:
    query = select(Bill).where(Bill.user_id == user.id, Bill.deleted_at.is_(None))
    if not include_paid:
        query = query.where(Bill.is_paid.is_(False))
    return list(db.scalars(query.order_by(Bill.due_date).limit(limit)).all())


@router.get("/bills/{bill_id}", response_model=BillRead)
def get_bill(
    bill_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Bill:
    return owned_or_404(db, Bill, bill_id, user.id)


@router.patch("/bills/{bill_id}", response_model=BillRead)
def update_bill(
    bill_id: str,
    payload: BillUpdate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Bill:
    bill = owned_or_404(db, Bill, bill_id, user.id)
    ensure_version(bill, payload.version)
    values = payload.model_dump(exclude_unset=True, exclude={"version"})
    validate_optional_links(
        db,
        user.id,
        account_id=values.get("account_id"),
        category_id=values.get("category_id"),
    )
    for field_name, value in values.items():
        if field_name.endswith("_id") and value is not None:
            value = str(value)
        setattr(bill, field_name, value)
    bill.version += 1
    db.commit()
    return bill


@router.delete("/bills/{bill_id}", response_model=MessageResponse)
def delete_bill(
    bill_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    bill = owned_or_404(db, Bill, bill_id, user.id)
    bill.deleted_at = utc_now()
    bill.version += 1
    db.commit()
    return MessageResponse(message="Bill deleted")


@router.post("/goals", response_model=GoalRead, status_code=status.HTTP_201_CREATED)
def create_goal(
    payload: GoalCreate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Goal:
    validate_optional_links(db, user.id, account_id=payload.linked_account_id)
    goal = Goal(
        user_id=user.id,
        name=payload.name.strip(),
        target_minor=payload.target_minor,
        current_minor=payload.current_minor,
        currency=payload.currency,
        target_date=payload.target_date,
        linked_account_id=(
            str(payload.linked_account_id) if payload.linked_account_id else None
        ),
        priority=payload.priority,
    )
    db.add(goal)
    db.commit()
    return goal


@router.get("/goals", response_model=list[GoalRead])
def list_goals(
    limit: int = Query(default=100, ge=1, le=200),
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[Goal]:
    return list(
        db.scalars(
            select(Goal)
            .where(Goal.user_id == user.id, Goal.deleted_at.is_(None))
            .order_by(Goal.priority, Goal.target_date)
            .limit(limit)
        ).all()
    )


@router.get("/goals/{goal_id}", response_model=GoalRead)
def get_goal(
    goal_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Goal:
    return owned_or_404(db, Goal, goal_id, user.id)


@router.patch("/goals/{goal_id}", response_model=GoalRead)
def update_goal(
    goal_id: str,
    payload: GoalUpdate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Goal:
    goal = owned_or_404(db, Goal, goal_id, user.id)
    ensure_version(goal, payload.version)
    current = {
        "name": goal.name,
        "target_minor": goal.target_minor,
        "current_minor": goal.current_minor,
        "currency": goal.currency,
        "target_date": goal.target_date,
        "linked_account_id": goal.linked_account_id,
        "priority": goal.priority,
    }
    current.update(payload.model_dump(exclude_unset=True, exclude={"version"}))
    validated = GoalCreate.model_validate(current)
    validate_optional_links(db, user.id, account_id=validated.linked_account_id)
    for key, value in validated.model_dump(mode="python").items():
        if key == "linked_account_id" and value is not None:
            value = str(value)
        setattr(goal, key, value)
    goal.version += 1
    db.commit()
    return goal


@router.delete("/goals/{goal_id}", response_model=MessageResponse)
def delete_goal(
    goal_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    goal = owned_or_404(db, Goal, goal_id, user.id)
    goal.deleted_at = utc_now()
    goal.version += 1
    db.commit()
    return MessageResponse(message="Goal deleted")
