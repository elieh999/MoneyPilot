from __future__ import annotations

from datetime import UTC

from fastapi import Depends, HTTPException, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from .database import get_db
from .models import User, UserSession, utc_now
from .security import decode_token

bearer_scheme = HTTPBearer(auto_error=False)


def get_current_user(
    request: Request,
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> User:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(status_code=401, detail="Authentication required")
    payload = decode_token(
        credentials.credentials, request.app.state.settings, "access"
    )
    user = db.get(User, str(payload["sub"]))
    session = db.get(UserSession, str(payload["sid"]))
    if user is None or not user.is_active or session is None:
        raise HTTPException(status_code=401, detail="Authentication session is invalid")
    expires = session.expires_at
    if expires.tzinfo is None:
        expires = expires.replace(tzinfo=UTC)
    if (
        session.revoked_at is not None
        or expires <= utc_now()
        or session.user_id != user.id
    ):
        raise HTTPException(status_code=401, detail="Authentication session is invalid")
    request.state.session_id = session.id
    return user
