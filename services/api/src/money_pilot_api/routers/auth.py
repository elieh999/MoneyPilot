from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy import select, update
from sqlalchemy.orm import Session

from ..database import get_db
from ..dependencies import get_current_user
from ..models import Category, User, UserSession, utc_now
from ..schemas import (
    LoginRequest,
    MessageResponse,
    RefreshRequest,
    RegisterRequest,
    TokenPair,
    UserRead,
)
from ..security import (
    create_session_tokens,
    hash_password,
    rotate_refresh_token,
    verify_password,
)

router = APIRouter(prefix="/auth", tags=["auth"])


DEFAULT_CATEGORIES = (
    ("Salary", "income"),
    ("Freelance", "income"),
    ("Groceries", "expense"),
    ("Housing", "expense"),
    ("Transportation", "expense"),
    ("Dining", "expense"),
    ("Utilities", "expense"),
    ("Healthcare", "expense"),
    ("Subscriptions", "expense"),
    ("Savings", "financial"),
    ("Debt payments", "financial"),
)


def seed_default_categories(db: Session, user_id: str) -> None:
    db.add_all(
        [
            Category(user_id=user_id, name=name, kind=kind)
            for name, kind in DEFAULT_CATEGORIES
        ]
    )


def token_response(tokens: object, user: User) -> TokenPair:
    return TokenPair(
        access_token=tokens.access_token,  # type: ignore[attr-defined]
        refresh_token=tokens.refresh_token,  # type: ignore[attr-defined]
        access_expires_in_seconds=tokens.access_expires_in_seconds,  # type: ignore[attr-defined]
        user=UserRead.model_validate(user),
    )


@router.post("/register", response_model=TokenPair, status_code=status.HTTP_201_CREATED)
def register(
    payload: RegisterRequest,
    request: Request,
    db: Session = Depends(get_db),
) -> TokenPair:
    email = str(payload.email).strip().lower()
    existing = db.scalar(select(User).where(User.email == email))
    if existing is not None:
        raise HTTPException(
            status_code=409, detail="An account with this email already exists"
        )
    user = User(
        email=email,
        password_hash=hash_password(payload.password),
        display_name=payload.display_name.strip(),
        currency=payload.currency,
    )
    db.add(user)
    db.flush()
    seed_default_categories(db, user.id)
    tokens = create_session_tokens(db, user, request.app.state.settings)
    db.commit()
    return token_response(tokens, user)


@router.post("/login", response_model=TokenPair)
def login(
    payload: LoginRequest,
    request: Request,
    db: Session = Depends(get_db),
) -> TokenPair:
    email = str(payload.email).strip().lower()
    user = db.scalar(select(User).where(User.email == email))
    if user is None or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    if not user.is_active:
        raise HTTPException(status_code=403, detail="Account is disabled")
    tokens = create_session_tokens(db, user, request.app.state.settings)
    db.commit()
    return token_response(tokens, user)


@router.post("/refresh", response_model=TokenPair)
def refresh(
    payload: RefreshRequest,
    request: Request,
    db: Session = Depends(get_db),
) -> TokenPair:
    tokens, user = rotate_refresh_token(
        db, payload.refresh_token, request.app.state.settings
    )
    db.commit()
    return token_response(tokens, user)


@router.get("/me", response_model=UserRead)
def me(user: User = Depends(get_current_user)) -> User:
    return user


@router.post("/logout", response_model=MessageResponse)
def logout(
    request: Request,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    session = db.get(UserSession, request.state.session_id)
    if session is not None and session.user_id == user.id:
        session.revoked_at = utc_now()
        db.commit()
    return MessageResponse(message="Signed out from this device")


@router.post("/logout-all", response_model=MessageResponse)
def logout_all(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    db.execute(
        update(UserSession)
        .where(UserSession.user_id == user.id, UserSession.revoked_at.is_(None))
        .values(revoked_at=utc_now())
    )
    db.commit()
    return MessageResponse(message="Signed out from all devices")
