from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Depends, HTTPException
from pydantic import ValidationError
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..database import get_db
from ..dependencies import get_current_user
from .. import models, schemas
from ..services import (
    create_transaction,
    delete_transaction,
    ensure_version,
    owned_or_404,
    update_transaction,
    validate_optional_links,
)


router = APIRouter(prefix="/sync", tags=["sync"])


MODEL_BY_ENTITY: dict[str, type] = {
    "account": models.Account,
    "category": models.Category,
    "transaction": models.Transaction,
    "budget": models.Budget,
    "bill": models.Bill,
    "goal": models.Goal,
}

READ_SCHEMA_BY_ENTITY: dict[str, type[schemas.APIModel]] = {
    "account": schemas.AccountRead,
    "category": schemas.CategoryRead,
    "transaction": schemas.TransactionRead,
    "budget": schemas.BudgetRead,
    "bill": schemas.BillRead,
    "goal": schemas.GoalRead,
}


def _serialize(entity_type: str, entity: Any) -> dict[str, Any]:
    return (
        READ_SCHEMA_BY_ENTITY[entity_type]
        .model_validate(entity)
        .model_dump(mode="json")
    )


def _create_entity(
    db: Session, user: models.User, operation: schemas.SyncOperationRequest
) -> Any:
    entity_id = (
        str(operation.entity_id) if operation.entity_id else models.uuid_string()
    )
    if db.get(MODEL_BY_ENTITY[operation.entity_type], entity_id) is not None:
        raise HTTPException(status_code=409, detail="Entity ID already exists")
    payload = operation.payload
    if operation.entity_type == "transaction":
        return create_transaction(
            db,
            user.id,
            schemas.TransactionCreate.model_validate(payload),
            entity_id=entity_id,
        )
    if operation.entity_type == "account":
        data = schemas.AccountCreate.model_validate(payload)
        entity = models.Account(
            id=entity_id,
            user_id=user.id,
            name=data.name,
            account_type=data.account_type,
            currency=data.currency,
            balance_minor=data.balance_minor,
            available_balance_minor=(
                data.balance_minor
                if data.available_balance_minor is None
                else data.available_balance_minor
            ),
            include_in_net_worth=data.include_in_net_worth,
            include_in_safe_to_spend=data.include_in_safe_to_spend,
            archived=data.archived,
            notes=data.notes,
        )
    elif operation.entity_type == "category":
        data = schemas.CategoryCreate.model_validate(payload)
        validate_optional_links(db, user.id, category_id=data.parent_id)
        entity = models.Category(
            id=entity_id,
            user_id=user.id,
            name=data.name,
            kind=data.kind,
            parent_id=str(data.parent_id) if data.parent_id else None,
        )
    elif operation.entity_type == "budget":
        data = schemas.BudgetCreate.model_validate(payload)
        validate_optional_links(db, user.id, category_id=data.category_id)
        entity = models.Budget(
            id=entity_id,
            user_id=user.id,
            name=data.name,
            category_id=str(data.category_id) if data.category_id else None,
            period_start=data.period_start,
            period_end=data.period_end,
            planned_minor=data.planned_minor,
            rollover_mode=data.rollover_mode,
        )
    elif operation.entity_type == "bill":
        data = schemas.BillCreate.model_validate(payload)
        validate_optional_links(
            db,
            user.id,
            account_id=data.account_id,
            category_id=data.category_id,
        )
        entity = models.Bill(
            id=entity_id,
            user_id=user.id,
            name=data.name,
            amount_minor=data.amount_minor,
            currency=data.currency,
            due_date=data.due_date,
            recurrence=data.recurrence,
            account_id=str(data.account_id) if data.account_id else None,
            category_id=str(data.category_id) if data.category_id else None,
            is_paid=data.is_paid,
            notes=data.notes,
        )
    else:
        data = schemas.GoalCreate.model_validate(payload)
        validate_optional_links(db, user.id, account_id=data.linked_account_id)
        entity = models.Goal(
            id=entity_id,
            user_id=user.id,
            name=data.name,
            target_minor=data.target_minor,
            current_minor=data.current_minor,
            currency=data.currency,
            target_date=data.target_date,
            linked_account_id=(
                str(data.linked_account_id) if data.linked_account_id else None
            ),
            priority=data.priority,
        )
    db.add(entity)
    db.flush()
    return entity


def _update_entity(
    db: Session, user: models.User, operation: schemas.SyncOperationRequest
) -> Any:
    model_type = MODEL_BY_ENTITY[operation.entity_type]
    entity = owned_or_404(db, model_type, operation.entity_id, user.id)
    ensure_version(entity, operation.base_version)
    if operation.entity_type == "transaction":
        payload = schemas.TransactionUpdate.model_validate(
            {**operation.payload, "version": operation.base_version}
        )
        return update_transaction(db, entity, payload)
    update_schema_by_entity = {
        "account": schemas.AccountUpdate,
        "category": schemas.CategoryUpdate,
        "budget": schemas.BudgetUpdate,
        "bill": schemas.BillUpdate,
        "goal": schemas.GoalUpdate,
    }
    data = update_schema_by_entity[operation.entity_type].model_validate(
        {**operation.payload, "version": operation.base_version}
    )
    values = data.model_dump(exclude_unset=True, exclude={"version"})
    if operation.entity_type == "category":
        validate_optional_links(db, user.id, category_id=values.get("parent_id"))
    elif operation.entity_type == "budget":
        validate_optional_links(db, user.id, category_id=values.get("category_id"))
    elif operation.entity_type == "bill":
        validate_optional_links(
            db,
            user.id,
            account_id=values.get("account_id"),
            category_id=values.get("category_id"),
        )
    elif operation.entity_type == "goal":
        validate_optional_links(db, user.id, account_id=values.get("linked_account_id"))
    for key, value in values.items():
        if key.endswith("_id") and value is not None:
            value = str(value)
        setattr(entity, key, value)
    entity.version += 1
    db.flush()
    # Re-validate cross-field invariants after applying the partial patch.
    if operation.entity_type == "budget":
        schemas.BudgetCreate.model_validate(_serialize("budget", entity))
    elif operation.entity_type == "goal":
        schemas.GoalCreate.model_validate(_serialize("goal", entity))
    return entity


def _delete_entity(
    db: Session, user: models.User, operation: schemas.SyncOperationRequest
) -> Any:
    model_type = MODEL_BY_ENTITY[operation.entity_type]
    entity = owned_or_404(db, model_type, operation.entity_id, user.id)
    ensure_version(entity, operation.base_version)
    if operation.entity_type == "transaction":
        delete_transaction(db, entity)
    else:
        entity.deleted_at = models.utc_now()
        if hasattr(entity, "archived"):
            entity.archived = True
        entity.version += 1
        db.flush()
    return entity


def _apply_operation(
    db: Session, user: models.User, operation: schemas.SyncOperationRequest
) -> tuple[Any, str]:
    if operation.operation == "create":
        return _create_entity(db, user, operation), "applied"
    if operation.operation == "update":
        return _update_entity(db, user, operation), "applied"
    return _delete_entity(db, user, operation), "applied"


@router.post("/operations", response_model=schemas.SyncBatchRead)
def apply_sync_operations(
    payload: schemas.SyncBatchRequest,
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> schemas.SyncBatchRead:
    responses: list[schemas.SyncOperationRead] = []
    for operation in payload.operations:
        existing = db.scalar(
            select(models.SyncOperation).where(
                models.SyncOperation.user_id == user.id,
                models.SyncOperation.client_operation_id
                == operation.client_operation_id,
            )
        )
        if existing is not None:
            responses.append(
                schemas.SyncOperationRead(
                    client_operation_id=existing.client_operation_id,
                    entity_type=existing.entity_type,
                    entity_id=existing.entity_id,
                    operation=existing.operation,
                    status=existing.status,
                    server_version=existing.server_version,
                    result=existing.result,
                    replayed=True,
                )
            )
            continue
        try:
            with db.begin_nested():
                entity, operation_status = _apply_operation(db, user, operation)
                result = _serialize(operation.entity_type, entity)
                entity_id = entity.id
                server_version = entity.version
        except HTTPException as exc:
            operation_status = "conflict" if exc.status_code == 409 else "rejected"
            result = {"detail": exc.detail}
            entity_id = str(operation.entity_id) if operation.entity_id else None
            server_version = None
        except ValidationError as exc:
            operation_status = "rejected"
            result = {"detail": exc.errors(include_url=False, include_context=False)}
            entity_id = str(operation.entity_id) if operation.entity_id else None
            server_version = None
        except IntegrityError:
            operation_status = "conflict"
            result = {
                "detail": "The operation violates a uniqueness or reference constraint"
            }
            entity_id = str(operation.entity_id) if operation.entity_id else None
            server_version = None
        record = models.SyncOperation(
            user_id=user.id,
            client_operation_id=operation.client_operation_id,
            entity_type=operation.entity_type,
            entity_id=entity_id,
            operation=operation.operation,
            base_version=operation.base_version,
            payload=operation.payload,
            result=result,
            status=operation_status,
            server_version=server_version,
        )
        db.add(record)
        db.flush()
        responses.append(
            schemas.SyncOperationRead(
                client_operation_id=record.client_operation_id,
                entity_type=record.entity_type,
                entity_id=record.entity_id,
                operation=record.operation,
                status=record.status,
                server_version=record.server_version,
                result=record.result,
            )
        )
    db.commit()
    return schemas.SyncBatchRead(operations=responses)
