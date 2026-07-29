from __future__ import annotations

import secrets
from datetime import UTC

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..ai import DISCLAIMER, AIToolService, proposal_payload_hash
from ..database import get_db
from ..dependencies import get_current_user
from ..models import AIActionProposal, Budget, User, utc_now
from ..schemas import (
    AIActionProposalRead,
    AIChatRead,
    AIChatRequest,
    AIProposalResolutionRead,
    BudgetCreate,
    BudgetRead,
)
from ..services import owned_or_404, validate_optional_links

router = APIRouter(prefix="/ai", tags=["ai"])
tool_service = AIToolService()


def _validate_pending_proposal(db: Session, proposal: AIActionProposal) -> None:
    if proposal.status != "pending":
        raise HTTPException(
            status_code=409, detail="Proposal has already been resolved"
        )
    now = utc_now()
    expires_at = proposal.expires_at
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=UTC)
    if expires_at <= now:
        proposal.status = "expired"
        proposal.resolved_at = now
        db.commit()
        raise HTTPException(status_code=409, detail="Proposal has expired")
    expected_hash = proposal_payload_hash(proposal.action_type, proposal.payload)
    if not secrets.compare_digest(proposal.payload_hash, expected_hash):
        proposal.status = "rejected"
        proposal.resolved_at = now
        db.commit()
        raise HTTPException(
            status_code=409, detail="Proposal payload integrity check failed"
        )


@router.post("/chat", response_model=AIChatRead)
def chat(
    payload: AIChatRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> AIChatRead:
    response, tool_name, tool_result, proposal = tool_service.chat(
        db, user, payload.message
    )
    db.commit()
    return AIChatRead(
        response=response,
        tool_name=tool_name,
        tool_result=tool_result,
        proposal=(
            AIActionProposalRead.model_validate(proposal)
            if proposal is not None
            else None
        ),
        disclaimer=DISCLAIMER,
    )


@router.get("/proposals", response_model=list[AIActionProposalRead])
def list_proposals(
    status_filter: str | None = None,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[AIActionProposal]:
    query = select(AIActionProposal).where(AIActionProposal.user_id == user.id)
    if status_filter:
        query = query.where(AIActionProposal.status == status_filter)
    return list(db.scalars(query.order_by(AIActionProposal.created_at.desc())).all())


@router.post(
    "/proposals/{proposal_id}/approve", response_model=AIProposalResolutionRead
)
def approve_proposal(
    proposal_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> AIProposalResolutionRead:
    proposal = owned_or_404(db, AIActionProposal, proposal_id, user.id)
    _validate_pending_proposal(db, proposal)
    created_resource: dict | None = None
    if proposal.action_type == "create_budget":
        payload = BudgetCreate.model_validate(proposal.payload)
        validate_optional_links(db, user.id, category_id=payload.category_id)
        budget = Budget(
            user_id=user.id,
            name=payload.name,
            category_id=str(payload.category_id) if payload.category_id else None,
            period_start=payload.period_start,
            period_end=payload.period_end,
            planned_minor=payload.planned_minor,
            rollover_mode=payload.rollover_mode,
        )
        db.add(budget)
        db.flush()
        created_resource = BudgetRead.model_validate(budget).model_dump(mode="json")
    else:
        raise HTTPException(status_code=422, detail="Unsupported proposal action")
    proposal.status = "approved"
    proposal.resolved_at = utc_now()
    db.commit()
    return AIProposalResolutionRead(
        proposal=AIActionProposalRead.model_validate(proposal),
        created_resource=created_resource,
    )


@router.post("/proposals/{proposal_id}/reject", response_model=AIProposalResolutionRead)
def reject_proposal(
    proposal_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> AIProposalResolutionRead:
    proposal = owned_or_404(db, AIActionProposal, proposal_id, user.id)
    _validate_pending_proposal(db, proposal)
    proposal.status = "rejected"
    proposal.resolved_at = utc_now()
    db.commit()
    return AIProposalResolutionRead(
        proposal=AIActionProposalRead.model_validate(proposal), created_resource=None
    )
