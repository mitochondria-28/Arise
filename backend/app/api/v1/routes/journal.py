import uuid

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user
from app.core.exceptions import ConflictError, NotFoundError, ValidationError
from app.database.session import get_db
from app.models.user import User
from app.schemas.journal import (
    CreateJournalRequest,
    JournalEntryResponse,
    JournalListResponse,
    JournalStreakResponse,
    UpdateJournalRequest,
)
from app.services.journal_service import JournalService

router = APIRouter(prefix="/journal", tags=["journal"])


@router.get("", response_model=JournalListResponse)
async def list_journal_entries(
    limit: int = Query(30, ge=1, le=100),
    offset: int = Query(0, ge=0),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    entries, total, streak = await JournalService(db).list_entries(
        current_user.id, limit=limit, offset=offset
    )
    return JournalListResponse(
        entries=[JournalEntryResponse.model_validate(e) for e in entries],
        total=total,
        streak=streak,
    )


@router.get("/streak", response_model=JournalStreakResponse)
async def get_journal_streak(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = JournalService(db)
    _, total, streak = await service.list_entries(current_user.id, limit=1, offset=0)
    return JournalStreakResponse(streak=streak, total_entries=total)


@router.get("/today", response_model=JournalEntryResponse | None)
async def get_today_entry(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    entry = await JournalService(db).get_today(current_user.id)
    if entry is None:
        return None
    return JournalEntryResponse.model_validate(entry)


@router.post("", response_model=JournalEntryResponse, status_code=201)
async def create_or_update_entry(
    body: CreateJournalRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    entry = await JournalService(db).create_or_update(
        current_user.id,
        content=body.content,
        mood=body.mood,
        entry_date=body.entry_date,
    )
    return JournalEntryResponse.model_validate(entry)


@router.put("/{entry_id}", response_model=JournalEntryResponse)
async def update_entry(
    entry_id: uuid.UUID,
    body: UpdateJournalRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    try:
        entry = await JournalService(db).update(
            entry_id, current_user.id, content=body.content, mood=body.mood
        )
    except NotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    return JournalEntryResponse.model_validate(entry)


@router.post("/{entry_id}/reflect", response_model=JournalEntryResponse)
async def generate_reflection(
    entry_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    try:
        entry = await JournalService(db).generate_reflection(
            entry_id, current_user.id
        )
    except NotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except ValidationError as e:
        raise HTTPException(status_code=503, detail=str(e))
    return JournalEntryResponse.model_validate(entry)
