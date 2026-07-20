from __future__ import annotations

from dataclasses import dataclass
from datetime import timedelta
import hashlib
import json
from typing import Any, Protocol

from sqlalchemy import select
from sqlalchemy.orm import Session

from .models import AIActionProposal, Bill, User, utc_now
from .services import financial_summary, safe_to_spend_summary


DISCLAIMER = (
    "MoneyPilot AI provides educational guidance, not professional financial, "
    "tax, investment, or legal advice. Estimates depend on the data provided."
)


def proposal_payload_hash(action_type: str, payload: dict[str, Any]) -> str:
    canonical = json.dumps(
        payload, sort_keys=True, separators=(",", ":"), ensure_ascii=True
    )
    return hashlib.sha256(f"{action_type}:{canonical}".encode("utf-8")).hexdigest()


@dataclass(frozen=True, slots=True)
class ProviderDecision:
    tool_name: str


class AIProvider(Protocol):
    """Replaceable language-model decision interface.

    Providers select only from names supplied by the server. They never receive
    database handles and cannot execute arbitrary SQL or shell commands.
    """

    def choose_tool(
        self, message: str, allowed_tools: frozenset[str]
    ) -> ProviderDecision: ...


class DeterministicLocalAIProvider:
    """No-network development fallback with predictable behavior."""

    def choose_tool(
        self, message: str, allowed_tools: frozenset[str]
    ) -> ProviderDecision:
        normalized = message.casefold()
        if "budget" in normalized and any(
            word in normalized for word in ("create", "make", "draft", "propose")
        ):
            selected = "propose_budget"
        elif any(word in normalized for word in ("safe", "afford", "spend")):
            selected = "get_safe_to_spend"
        elif any(word in normalized for word in ("bill", "due", "upcoming")):
            selected = "list_upcoming_bills"
        else:
            selected = "get_financial_summary"
        if selected not in allowed_tools:
            selected = "get_financial_summary"
        return ProviderDecision(tool_name=selected)


class AIToolService:
    allowed_tools = frozenset(
        {
            "get_financial_summary",
            "get_safe_to_spend",
            "list_upcoming_bills",
            "propose_budget",
        }
    )

    def __init__(self, provider: AIProvider | None = None) -> None:
        self.provider = provider or DeterministicLocalAIProvider()

    def chat(
        self, db: Session, user: User, message: str
    ) -> tuple[
        str, str, dict[str, Any] | list[dict[str, Any]], AIActionProposal | None
    ]:
        decision = self.provider.choose_tool(message, self.allowed_tools)
        if decision.tool_name not in self.allowed_tools:
            raise ValueError("AI provider selected a non-allowlisted tool")
        if decision.tool_name == "get_safe_to_spend":
            result = safe_to_spend_summary(
                db, user, until_date=utc_now().date() + timedelta(days=30)
            )
            response = (
                f"Your current safe-to-spend estimate is "
                f"{result['safe_to_spend_minor']} {user.currency} minor units. "
                "The tool result includes every deduction and the calculation horizon."
            )
            return response, decision.tool_name, result, None
        if decision.tool_name == "list_upcoming_bills":
            today = utc_now().date()
            cutoff = today + timedelta(days=30)
            bills = db.scalars(
                select(Bill).where(
                    Bill.user_id == user.id,
                    Bill.deleted_at.is_(None),
                    Bill.is_paid.is_(False),
                    Bill.due_date >= today,
                    Bill.due_date <= cutoff,
                )
            ).all()
            result = [
                {
                    "id": bill.id,
                    "name": bill.name,
                    "amount_minor": bill.amount_minor,
                    "currency": bill.currency,
                    "due_date": bill.due_date.isoformat(),
                }
                for bill in bills
            ]
            response = (
                f"You have {len(result)} unpaid bill(s) due in the next 30 days. "
                "Review the dated list before making a decision."
            )
            return response, decision.tool_name, result, None
        if decision.tool_name == "propose_budget":
            safe = safe_to_spend_summary(
                db, user, until_date=utc_now().date() + timedelta(days=30)
            )
            today = utc_now().date()
            period_end = today + timedelta(days=29)
            suggested = max(int(safe["safe_to_spend_minor"]) // 2, 0)
            payload = {
                "name": "AI suggested flexible budget",
                "category_id": None,
                "period_start": today.isoformat(),
                "period_end": period_end.isoformat(),
                "planned_minor": suggested,
                "rollover_mode": "none",
            }
            action_type = "create_budget"
            proposal = AIActionProposal(
                user_id=user.id,
                action_type=action_type,
                payload=payload,
                payload_hash=proposal_payload_hash(action_type, payload),
                explanation=(
                    f"Draft a 30-day budget of {suggested} {user.currency} minor units, "
                    "using one half of the current safe-to-spend estimate as a conservative starting point."
                ),
                expires_at=utc_now() + timedelta(minutes=10),
            )
            db.add(proposal)
            db.flush()
            response = (
                "I prepared a budget draft. Nothing has changed yet; review and "
                "approve or reject the action proposal."
            )
            return response, decision.tool_name, payload, proposal
        result = financial_summary(db, user)
        response = (
            f"This month you recorded {result['current_month_income_minor']} income "
            f"and {result['current_month_expenses_minor']} expenses in {user.currency} "
            "minor units. The structured summary contains the supporting totals."
        )
        return response, "get_financial_summary", result, None
