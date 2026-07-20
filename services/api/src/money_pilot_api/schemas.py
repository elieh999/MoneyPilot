from __future__ import annotations

from datetime import date, datetime, timezone
from typing import Any, Literal
from uuid import UUID

from pydantic import (
    BaseModel,
    ConfigDict,
    EmailStr,
    Field,
    field_validator,
    model_validator,
)


CurrencyCode = str
AccountType = Literal[
    "cash",
    "checking",
    "savings",
    "credit_card",
    "prepaid",
    "investment",
    "loan",
    "wallet",
    "custom",
]
TransactionType = Literal[
    "expense",
    "income",
    "transfer",
    "refund",
    "debt_payment",
    "investment_contribution",
    "account_adjustment",
    "reimbursement",
]
TransactionStatus = Literal["cleared", "pending"]


class APIModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)


def _currency(value: str) -> str:
    normalized = value.strip().upper()
    if len(normalized) != 3 or not normalized.isalpha():
        raise ValueError("currency must be a three-letter ISO-style code")
    return normalized


class RegisterRequest(APIModel):
    email: EmailStr
    password: str = Field(min_length=10, max_length=256)
    display_name: str = Field(min_length=1, max_length=100)
    currency: str = Field(default="USD")

    _normalize_currency = field_validator("currency")(_currency)


class LoginRequest(APIModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=256)


class RefreshRequest(APIModel):
    refresh_token: str = Field(min_length=20)


class UserRead(APIModel):
    id: UUID
    email: EmailStr
    display_name: str
    currency: str
    created_at: datetime


class TokenPair(APIModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    access_expires_in_seconds: int
    user: UserRead


class MessageResponse(APIModel):
    message: str


class AccountCreate(APIModel):
    name: str = Field(min_length=1, max_length=100)
    account_type: AccountType
    currency: str = "USD"
    balance_minor: int = 0
    available_balance_minor: int | None = None
    include_in_net_worth: bool = True
    include_in_safe_to_spend: bool = True
    archived: bool = False
    notes: str | None = Field(default=None, max_length=2_000)

    _normalize_currency = field_validator("currency")(_currency)


class AccountUpdate(APIModel):
    name: str | None = Field(default=None, min_length=1, max_length=100)
    account_type: AccountType | None = None
    include_in_net_worth: bool | None = None
    include_in_safe_to_spend: bool | None = None
    archived: bool | None = None
    notes: str | None = Field(default=None, max_length=2_000)
    version: int | None = Field(default=None, ge=1)


class AccountRead(APIModel):
    id: UUID
    name: str
    account_type: str
    currency: str
    balance_minor: int
    available_balance_minor: int
    include_in_net_worth: bool
    include_in_safe_to_spend: bool
    archived: bool
    notes: str | None
    version: int
    created_at: datetime
    updated_at: datetime


class CategoryCreate(APIModel):
    name: str = Field(min_length=1, max_length=80)
    kind: Literal["income", "expense", "financial"]
    parent_id: UUID | None = None


class CategoryUpdate(APIModel):
    name: str | None = Field(default=None, min_length=1, max_length=80)
    kind: Literal["income", "expense", "financial"] | None = None
    parent_id: UUID | None = None
    archived: bool | None = None
    version: int | None = Field(default=None, ge=1)


class CategoryRead(APIModel):
    id: UUID
    name: str
    kind: str
    parent_id: UUID | None
    archived: bool
    version: int
    created_at: datetime
    updated_at: datetime


class TransactionCreate(APIModel):
    transaction_type: TransactionType
    amount_minor: int = Field(gt=0)
    currency: str = "USD"
    occurred_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    account_id: UUID
    destination_account_id: UUID | None = None
    category_id: UUID | None = None
    merchant: str | None = Field(default=None, max_length=120)
    description: str | None = Field(default=None, max_length=255)
    notes: str | None = Field(default=None, max_length=2_000)
    status: TransactionStatus = "cleared"

    _normalize_currency = field_validator("currency")(_currency)

    @model_validator(mode="after")
    def validate_transfer(self) -> "TransactionCreate":
        if self.transaction_type == "transfer":
            if self.destination_account_id is None:
                raise ValueError("destination_account_id is required for transfers")
            if self.destination_account_id == self.account_id:
                raise ValueError("transfer accounts must be different")
        elif self.destination_account_id is not None:
            raise ValueError("destination_account_id is only valid for transfers")
        return self


class TransactionUpdate(APIModel):
    transaction_type: TransactionType | None = None
    amount_minor: int | None = Field(default=None, gt=0)
    currency: str | None = None
    occurred_at: datetime | None = None
    account_id: UUID | None = None
    destination_account_id: UUID | None = None
    category_id: UUID | None = None
    merchant: str | None = Field(default=None, max_length=120)
    description: str | None = Field(default=None, max_length=255)
    notes: str | None = Field(default=None, max_length=2_000)
    status: TransactionStatus | None = None
    version: int | None = Field(default=None, ge=1)

    @field_validator("currency")
    @classmethod
    def normalize_optional_currency(cls, value: str | None) -> str | None:
        return None if value is None else _currency(value)


class TransactionRead(APIModel):
    id: UUID
    transaction_type: str
    amount_minor: int
    currency: str
    occurred_at: datetime
    account_id: UUID
    destination_account_id: UUID | None
    category_id: UUID | None
    merchant: str | None
    description: str | None
    notes: str | None
    status: str
    version: int
    created_at: datetime
    updated_at: datetime
    deleted_at: datetime | None


class BudgetCreate(APIModel):
    name: str = Field(min_length=1, max_length=100)
    category_id: UUID | None = None
    period_start: date
    period_end: date
    planned_minor: int = Field(ge=0)
    rollover_mode: Literal["none", "positive", "overspending", "both"] = "none"

    @model_validator(mode="after")
    def validate_period(self) -> "BudgetCreate":
        if self.period_end < self.period_start:
            raise ValueError("period_end cannot be before period_start")
        return self


class BudgetUpdate(APIModel):
    name: str | None = Field(default=None, min_length=1, max_length=100)
    category_id: UUID | None = None
    period_start: date | None = None
    period_end: date | None = None
    planned_minor: int | None = Field(default=None, ge=0)
    rollover_mode: Literal["none", "positive", "overspending", "both"] | None = None
    version: int | None = Field(default=None, ge=1)


class BudgetRead(APIModel):
    id: UUID
    name: str
    category_id: UUID | None
    period_start: date
    period_end: date
    planned_minor: int
    rollover_mode: str
    version: int
    created_at: datetime
    updated_at: datetime


class BillCreate(APIModel):
    name: str = Field(min_length=1, max_length=100)
    amount_minor: int = Field(ge=0)
    currency: str = "USD"
    due_date: date
    recurrence: Literal[
        "none", "weekly", "biweekly", "monthly", "quarterly", "yearly", "custom"
    ] = "none"
    account_id: UUID | None = None
    category_id: UUID | None = None
    is_paid: bool = False
    notes: str | None = Field(default=None, max_length=2_000)

    _normalize_currency = field_validator("currency")(_currency)


class BillUpdate(APIModel):
    name: str | None = Field(default=None, min_length=1, max_length=100)
    amount_minor: int | None = Field(default=None, ge=0)
    due_date: date | None = None
    recurrence: (
        Literal[
            "none", "weekly", "biweekly", "monthly", "quarterly", "yearly", "custom"
        ]
        | None
    ) = None
    account_id: UUID | None = None
    category_id: UUID | None = None
    is_paid: bool | None = None
    notes: str | None = Field(default=None, max_length=2_000)
    version: int | None = Field(default=None, ge=1)


class BillRead(APIModel):
    id: UUID
    name: str
    amount_minor: int
    currency: str
    due_date: date
    recurrence: str
    account_id: UUID | None
    category_id: UUID | None
    is_paid: bool
    notes: str | None
    version: int
    created_at: datetime
    updated_at: datetime


class GoalCreate(APIModel):
    name: str = Field(min_length=1, max_length=100)
    target_minor: int = Field(gt=0)
    current_minor: int = Field(default=0, ge=0)
    currency: str = "USD"
    target_date: date | None = None
    linked_account_id: UUID | None = None
    priority: int = Field(default=3, ge=1, le=5)

    _normalize_currency = field_validator("currency")(_currency)

    @model_validator(mode="after")
    def validate_current(self) -> "GoalCreate":
        if self.current_minor > self.target_minor:
            raise ValueError("current_minor cannot exceed target_minor")
        return self


class GoalUpdate(APIModel):
    name: str | None = Field(default=None, min_length=1, max_length=100)
    target_minor: int | None = Field(default=None, gt=0)
    current_minor: int | None = Field(default=None, ge=0)
    target_date: date | None = None
    linked_account_id: UUID | None = None
    priority: int | None = Field(default=None, ge=1, le=5)
    version: int | None = Field(default=None, ge=1)


class GoalRead(APIModel):
    id: UUID
    name: str
    target_minor: int
    current_minor: int
    currency: str
    target_date: date | None
    linked_account_id: UUID | None
    priority: int
    version: int
    created_at: datetime
    updated_at: datetime


class DashboardRead(APIModel):
    currency: str
    total_available_balance_minor: int
    current_month_income_minor: int
    current_month_expenses_minor: int
    net_cash_flow_minor: int
    savings_rate_basis_points: int
    upcoming_bills_minor: int
    upcoming_bill_count: int
    goal_saved_minor: int
    goal_target_minor: int
    safe_to_spend_minor: int
    safe_to_spend_shortfall_minor: int
    excluded_currency_account_count: int


class SafeToSpendRead(APIModel):
    currency: str
    until_date: date
    safe_to_spend_minor: int
    raw_safe_to_spend_minor: int
    shortfall_minor: int
    minimum_untouched_minor: int
    available_balance_minor: int
    confirmed_income_minor: int
    deductions: dict[str, int]
    daily_allowance_minor: int
    explanation: list[str]


class SyncOperationRequest(APIModel):
    client_operation_id: str = Field(min_length=1, max_length=100)
    entity_type: Literal["account", "category", "transaction", "budget", "bill", "goal"]
    entity_id: UUID | None = None
    operation: Literal["create", "update", "delete"]
    base_version: int | None = Field(default=None, ge=1)
    payload: dict[str, Any] = Field(default_factory=dict)

    @model_validator(mode="after")
    def validate_operation(self) -> "SyncOperationRequest":
        if self.operation != "create" and self.entity_id is None:
            raise ValueError("entity_id is required for update and delete")
        if self.operation == "update" and self.base_version is None:
            raise ValueError("base_version is required for update")
        return self


class SyncOperationRead(APIModel):
    client_operation_id: str
    entity_type: str
    entity_id: UUID | None
    operation: str
    status: str
    server_version: int | None
    result: dict[str, Any]
    replayed: bool = False


class SyncBatchRequest(APIModel):
    operations: list[SyncOperationRequest] = Field(min_length=1, max_length=100)


class SyncBatchRead(APIModel):
    operations: list[SyncOperationRead]


class AIChatRequest(APIModel):
    message: str = Field(min_length=1, max_length=2_000)


class AIActionProposalRead(APIModel):
    id: UUID
    action_type: str
    payload: dict[str, Any]
    explanation: str
    status: str
    created_at: datetime
    expires_at: datetime
    resolved_at: datetime | None


class AIChatRead(APIModel):
    response: str
    tool_name: str
    tool_result: dict[str, Any] | list[dict[str, Any]]
    proposal: AIActionProposalRead | None = None
    disclaimer: str


class AIProposalResolutionRead(APIModel):
    proposal: AIActionProposalRead
    created_resource: dict[str, Any] | None = None


class DemoSeedRead(APIModel):
    email: EmailStr
    password: str
    user_id: UUID
    seeded: bool
