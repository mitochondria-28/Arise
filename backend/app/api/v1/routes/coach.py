import uuid

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user
from app.database.session import get_db
from app.models.user import User
from app.schemas.coach import (
    AIConversationResponse,
    AIConversationSummary,
    AIMessageResponse,
    CreateConversationRequest,
    SendMessageRequest,
    WeeklyReviewResponse,
)
from app.services.coach_service import CoachService

router = APIRouter(prefix="/coach", tags=["coach"])


@router.get("/conversations", response_model=list[AIConversationSummary])
async def list_conversations(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await CoachService(db).list_conversations(current_user.id)


@router.post("/conversations", response_model=AIConversationSummary, status_code=201)
async def create_conversation(
    body: CreateConversationRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await CoachService(db).create_conversation(current_user.id, title=body.title)


@router.get("/conversations/{conversation_id}", response_model=AIConversationResponse)
async def get_conversation(
    conversation_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    conv = await CoachService(db).get_conversation(conversation_id, current_user.id)
    if not conv:
        raise HTTPException(status_code=404, detail="Conversation not found.")
    return conv


@router.post(
    "/conversations/{conversation_id}/messages",
    response_model=AIMessageResponse,
    status_code=201,
)
async def send_message(
    conversation_id: uuid.UUID,
    body: SendMessageRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    try:
        msg = await CoachService(db).send_message(
            conversation_id=conversation_id,
            user_id=current_user.id,
            user_text=body.content,
        )
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
    return msg


# ── Weekly Reviews ─────────────────────────────────────────────────────────────

@router.get("/weekly-reviews", response_model=list[WeeklyReviewResponse])
async def list_weekly_reviews(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    reviews = await CoachService(db).list_weekly_reviews(current_user.id)
    return [WeeklyReviewResponse.from_orm_obj(r) for r in reviews]


@router.post("/weekly-reviews/generate", response_model=WeeklyReviewResponse, status_code=201)
async def generate_weekly_review(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    review = await CoachService(db).get_or_generate_weekly_review(current_user.id)
    if review is None:
        raise HTTPException(
            status_code=503,
            detail="AI service unavailable. Configure GEMINI_API_KEY to enable reviews.",
        )
    return WeeklyReviewResponse.from_orm_obj(review)
