from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user
from app.database.session import get_db
from app.models.user import User
from app.schemas.skill import PracticeRequest, PracticeResponse, SkillResponse, UserSkillResponse
from app.services.skill_service import SkillService

import uuid

router = APIRouter(prefix="/skills", tags=["skills"])


@router.get("", response_model=list[SkillResponse])
async def list_catalog(
    category: str | None = Query(
        None,
        pattern="^(vitality|strength|intelligence|wisdom|charisma|discipline)$",
    ),
    _: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await SkillService(db).list_catalog(category=category)


@router.get("/me", response_model=list[UserSkillResponse])
async def get_my_skills(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await SkillService(db).get_user_skills(current_user.id)


@router.post("/{skill_id}/unlock", response_model=UserSkillResponse, status_code=201)
async def unlock_skill(
    skill_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await SkillService(db).unlock(current_user.id, skill_id)


@router.post("/{skill_id}/practice", response_model=PracticeResponse)
async def practice_skill(
    skill_id: uuid.UUID,
    payload: PracticeRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await SkillService(db).practice(
        current_user.id,
        skill_id,
        notes=payload.notes,
        duration_minutes=payload.duration_minutes,
    )
