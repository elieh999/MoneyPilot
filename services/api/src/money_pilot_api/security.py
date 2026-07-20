from __future__ import annotations

import hashlib
import secrets
import uuid
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Any

import jwt
from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerificationError, VerifyMismatchError
from argon2.low_level import Type
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from .config import Settings
from .models import User, UserSession, utc_now


ALGORITHM = "HS256"
PASSWORD_HASHER = PasswordHasher(
    time_cost=3,
    memory_cost=65_536,
    parallelism=4,
    hash_len=32,
    salt_len=16,
    type=Type.ID,
)


@dataclass(frozen=True, slots=True)
class IssuedTokens:
    access_token: str
    refresh_token: str
    access_expires_in_seconds: int


def hash_password(password: str) -> str:
    return PASSWORD_HASHER.hash(password)


def verify_password(password: str, stored_hash: str) -> bool:
    if not stored_hash.startswith("$argon2id$"):
        return False
    try:
        return PASSWORD_HASHER.verify(stored_hash, password)
    except (VerifyMismatchError, VerificationError, InvalidHashError):
        return False


def _hash_jti(jti: str) -> str:
    return hashlib.sha256(jti.encode("ascii")).hexdigest()


def _encode_token(
    *,
    user_id: str,
    session_id: str,
    token_type: str,
    expires_at: datetime,
    secret: str,
    jti: str,
) -> str:
    now = utc_now()
    payload: dict[str, Any] = {
        "sub": user_id,
        "sid": session_id,
        "type": token_type,
        "jti": jti,
        "iat": now,
        "exp": expires_at,
    }
    return jwt.encode(payload, secret, algorithm=ALGORITHM)


def create_session_tokens(db: Session, user: User, settings: Settings) -> IssuedTokens:
    session_id = str(uuid.uuid4())
    refresh_jti = secrets.token_urlsafe(32)
    refresh_expires = utc_now() + timedelta(days=settings.refresh_token_days)
    session = UserSession(
        id=session_id,
        user_id=user.id,
        refresh_jti_hash=_hash_jti(refresh_jti),
        expires_at=refresh_expires,
    )
    db.add(session)
    db.flush()
    return _issue_for_session(
        session=session,
        user=user,
        settings=settings,
        refresh_jti=refresh_jti,
    )


def _issue_for_session(
    *,
    session: UserSession,
    user: User,
    settings: Settings,
    refresh_jti: str,
) -> IssuedTokens:
    access_expires = utc_now() + timedelta(minutes=settings.access_token_minutes)
    access_jti = secrets.token_urlsafe(18)
    access = _encode_token(
        user_id=user.id,
        session_id=session.id,
        token_type="access",
        expires_at=access_expires,
        secret=settings.jwt_secret,
        jti=access_jti,
    )
    refresh = _encode_token(
        user_id=user.id,
        session_id=session.id,
        token_type="refresh",
        expires_at=session.expires_at,
        secret=settings.jwt_secret,
        jti=refresh_jti,
    )
    return IssuedTokens(
        access_token=access,
        refresh_token=refresh,
        access_expires_in_seconds=settings.access_token_minutes * 60,
    )


def decode_token(token: str, settings: Settings, expected_type: str) -> dict[str, Any]:
    credentials_error = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid or expired authentication token",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.jwt_secret, algorithms=[ALGORITHM])
    except jwt.PyJWTError as exc:
        raise credentials_error from exc
    if (
        payload.get("type") != expected_type
        or not payload.get("sub")
        or not payload.get("sid")
    ):
        raise credentials_error
    return payload


def rotate_refresh_token(
    db: Session, token: str, settings: Settings
) -> tuple[IssuedTokens, User]:
    payload = decode_token(token, settings, "refresh")
    session = db.get(UserSession, str(payload["sid"]))
    user = db.get(User, str(payload["sub"]))
    if session is None or user is None or not user.is_active:
        raise HTTPException(status_code=401, detail="Refresh session is not valid")
    if session.user_id != user.id or session.revoked_at is not None:
        raise HTTPException(status_code=401, detail="Refresh session is not valid")
    expires = session.expires_at
    if expires.tzinfo is None:
        expires = expires.replace(tzinfo=timezone.utc)
    if expires <= utc_now():
        raise HTTPException(status_code=401, detail="Refresh session has expired")
    supplied_jti = str(payload.get("jti", ""))
    if not secrets.compare_digest(session.refresh_jti_hash, _hash_jti(supplied_jti)):
        session.revoked_at = utc_now()
        # A replay attempt revokes the whole session even though the HTTP request
        # itself returns an error and the normal dependency path rolls back.
        db.commit()
        raise HTTPException(
            status_code=401,
            detail="Refresh token reuse detected; session revoked",
        )
    new_jti = secrets.token_urlsafe(32)
    session.refresh_jti_hash = _hash_jti(new_jti)
    db.flush()
    return (
        _issue_for_session(
            session=session,
            user=user,
            settings=settings,
            refresh_jti=new_jti,
        ),
        user,
    )
