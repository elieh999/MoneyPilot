from __future__ import annotations

from datetime import date, timedelta

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from ..database import get_db
from ..dependencies import get_current_user
from ..models import User, utc_now
from ..schemas import DashboardRead, SafeToSpendRead
from ..services import financial_summary, safe_to_spend_summary


router = APIRouter(tags=["dashboard"])


@router.get("/dashboard/summary", response_model=DashboardRead)
def dashboard_summary(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    return financial_summary(db, user)


@router.get("/safe-to-spend", response_model=SafeToSpendRead)
def safe_to_spend(
    until_date: date | None = None,
    confirmed_income_minor: int = Query(default=0, ge=0),
    debt_minimum_payments_minor: int = Query(default=0, ge=0),
    planned_savings_minor: int = Query(default=0, ge=0),
    goal_contributions_minor: int = Query(default=0, ge=0),
    emergency_reserve_minor: int = Query(default=0, ge=0),
    credit_card_obligations_minor: int = Query(default=0, ge=0),
    safety_buffer_minor: int = Query(default=0, ge=0),
    known_one_time_expenses_minor: int = Query(default=0, ge=0),
    forecast_uncertainty_buffer_minor: int = Query(default=0, ge=0),
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    horizon = until_date or (utc_now().date() + timedelta(days=30))
    return safe_to_spend_summary(
        db,
        user,
        until_date=horizon,
        confirmed_income_minor=confirmed_income_minor,
        debt_minimum_payments_minor=debt_minimum_payments_minor,
        planned_savings_minor=planned_savings_minor,
        goal_contributions_minor=goal_contributions_minor,
        emergency_reserve_minor=emergency_reserve_minor,
        credit_card_obligations_minor=credit_card_obligations_minor,
        safety_buffer_minor=safety_buffer_minor,
        known_one_time_expenses_minor=known_one_time_expenses_minor,
        forecast_uncertainty_buffer_minor=forecast_uncertainty_buffer_minor,
    )
