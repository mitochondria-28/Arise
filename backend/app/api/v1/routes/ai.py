import uuid

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user
from app.database.session import get_db
from app.models.goal import Goal
from app.models.mission import Mission
from app.models.user import User
from app.repositories.ai_repository import AIAnalysisRepository
from app.repositories.character_repository import CharacterRepository
from app.schemas.ai import AIAnalysisResponse
from app.services.ai_service import AIService

router = APIRouter(prefix="/ai", tags=["ai"])


@router.get("/analysis/goal/{goal_id}", response_model=AIAnalysisResponse)
async def get_goal_analysis(
    goal_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    goal = (
        await db.execute(
            select(Goal).where(Goal.id == goal_id, Goal.user_id == current_user.id)
        )
    ).scalar_one_or_none()
    if not goal:
        raise HTTPException(status_code=404, detail="Goal not found.")

    character = await CharacterRepository(db).get_by_user_id(current_user.id, load_stats=False)
    if not character:
        raise HTTPException(status_code=404, detail="Character not found.")

    analysis = await AIAnalysisRepository(db).get_latest_by_source(
        source_type="goal", source_id=goal_id
    )
    if not analysis:
        raise HTTPException(status_code=404, detail="No AI analysis available yet.")

    return analysis


@router.get("/analysis/mission/{mission_id}", response_model=AIAnalysisResponse)
async def get_mission_analysis(
    mission_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    mission = (
        await db.execute(
            select(Mission).where(
                Mission.id == mission_id, Mission.user_id == current_user.id
            )
        )
    ).scalar_one_or_none()
    if not mission:
        raise HTTPException(status_code=404, detail="Mission not found.")

    analysis = await AIAnalysisRepository(db).get_latest_by_source(
        source_type="mission", source_id=mission_id
    )
    if not analysis:
        raise HTTPException(status_code=404, detail="No AI analysis available yet.")

    return analysis


@router.post("/growth-report", response_model=AIAnalysisResponse)
async def generate_growth_report(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Generate a personalised growth report based on the user's current character data."""
    character = await CharacterRepository(db).get_by_user_id(current_user.id, load_stats=False)
    if not character:
        raise HTTPException(status_code=404, detail="Character not found.")

    analysis = await AIService(db).generate_growth_report(
        character_id=character.id,
        user_id=current_user.id,
    )
    if analysis is None:
        raise HTTPException(
            status_code=503,
            detail="AI service unavailable. Configure GEMINI_API_KEY to enable insights.",
        )

    return analysis
