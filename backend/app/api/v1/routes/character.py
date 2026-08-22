from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user
from app.database.session import get_db
from app.models.user import User
from app.schemas.character import CharacterResponse, XPHistoryResponse
from app.services.character_service import CharacterService

router = APIRouter(prefix="/character", tags=["character"])


@router.get("", response_model=CharacterResponse)
async def get_character(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await CharacterService(db).get_for_user(current_user.id)


@router.get("/xp/history", response_model=XPHistoryResponse)
async def get_xp_history(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
):
    service = CharacterService(db)
    character = await service.get_for_user(current_user.id)
    transactions, total = await service.get_xp_history(
        character.id, page=page, page_size=page_size
    )
    return XPHistoryResponse(
        transactions=transactions,
        total=total,
        page=page,
        page_size=page_size,
    )
