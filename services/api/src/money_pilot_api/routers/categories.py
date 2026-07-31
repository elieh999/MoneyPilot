from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..database import get_db
from ..dependencies import get_current_user
from ..models import Category, User, utc_now
from ..schemas import CategoryCreate, CategoryRead, CategoryUpdate, MessageResponse
from ..services import ensure_version, owned_or_404

router = APIRouter(prefix="/categories", tags=["categories"])


@router.post("", response_model=CategoryRead, status_code=status.HTTP_201_CREATED)
def create_category(
    payload: CategoryCreate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Category:
    if db.scalar(
        select(Category).where(
            Category.user_id == user.id,
            Category.name == payload.name.strip(),
            Category.deleted_at.is_(None),
        )
    ):
        raise HTTPException(status_code=409, detail="Category name already exists")
    if payload.parent_id is not None:
        owned_or_404(db, Category, payload.parent_id, user.id)
    category = Category(
        user_id=user.id,
        name=payload.name.strip(),
        kind=payload.kind,
        parent_id=str(payload.parent_id) if payload.parent_id else None,
    )
    db.add(category)
    db.commit()
    return category


@router.get("", response_model=list[CategoryRead])
def list_categories(
    include_archived: bool = False,
    limit: int = Query(default=200, ge=1, le=500),
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[Category]:
    query = select(Category).where(
        Category.user_id == user.id, Category.deleted_at.is_(None)
    )
    if not include_archived:
        query = query.where(Category.archived.is_(False))
    return list(
        db.scalars(query.order_by(Category.kind, Category.name).limit(limit)).all()
    )


@router.get("/{category_id}", response_model=CategoryRead)
def get_category(
    category_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Category:
    return owned_or_404(db, Category, category_id, user.id)


@router.patch("/{category_id}", response_model=CategoryRead)
def update_category(
    category_id: str,
    payload: CategoryUpdate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Category:
    category = owned_or_404(db, Category, category_id, user.id)
    ensure_version(category, payload.version)
    values = payload.model_dump(exclude_unset=True, exclude={"version"})
    if "parent_id" in values and values["parent_id"] is not None:
        if str(values["parent_id"]) == category.id:
            raise HTTPException(
                status_code=422, detail="Category cannot be its own parent"
            )
        owned_or_404(db, Category, values["parent_id"], user.id)
        values["parent_id"] = str(values["parent_id"])
    for field_name, value in values.items():
        setattr(category, field_name, value)
    category.version += 1
    db.commit()
    return category


@router.delete("/{category_id}", response_model=MessageResponse)
def delete_category(
    category_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    category = owned_or_404(db, Category, category_id, user.id)
    category.deleted_at = utc_now()
    category.archived = True
    category.version += 1
    db.commit()
    return MessageResponse(message="Category archived")
