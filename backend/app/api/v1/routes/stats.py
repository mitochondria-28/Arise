from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user
from app.database.session import get_db
from app.models.user import User
from app.repositories.stat_snapshot_repository import StatSnapshotRepository
from app.repositories.stats_repository import StatsRepository
from app.schemas.stats import StatHistoryEntry, StatHistoryResponse, StatsSummaryResponse, XPHistoryResponse
from app.services.character_service import CharacterService

router = APIRouter(prefix="/stats", tags=["stats"])


@router.get("/summary", response_model=StatsSummaryResponse)
async def get_stats_summary(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    character = await CharacterService(db).get_for_user(current_user.id)
    repo = StatsRepository(db)

    goal_data = await repo.get_goal_summary(current_user.id)
    mission_data = await repo.get_mission_summary(current_user.id)

    return StatsSummaryResponse(
        total_xp=character.total_xp,
        current_level=character.level,
        rank=character.rank,
        goals_completed=goal_data["total_goals_completed"],
        goals_by_difficulty=goal_data["goals_by_difficulty"],
        goals_by_category=goal_data["goals_by_category"],
        missions_active=mission_data["missions_active"],
        total_checkins=mission_data["total_checkins"],
        best_streak=mission_data["best_streak"],
        current_streak_max=mission_data["current_streak_max"],
        top_missions=mission_data["top_missions"],
    )


@router.get("/xp-history", response_model=XPHistoryResponse)
async def get_xp_history(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    days: int = Query(30, ge=7, le=365),
):
    character = await CharacterService(db).get_for_user(current_user.id)
    data = await StatsRepository(db).get_xp_history(character.id, days=days)
    return XPHistoryResponse(**data)


@router.get("/stat-history", response_model=StatHistoryResponse)
async def get_stat_history(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    days: int = Query(30, ge=7, le=90),
):
    character = await CharacterService(db).get_for_user(current_user.id)
    snapshots = await StatSnapshotRepository(db).get_history(character.id, days=days)
    entries = [
        StatHistoryEntry(
            date=str(s.snapshot_date),
            vitality=s.vitality,
            strength=s.strength,
            intelligence=s.intelligence,
            wisdom=s.wisdom,
            charisma=s.charisma,
            discipline=s.discipline,
            total_xp=s.total_xp,
            level=s.level,
        )
        for s in snapshots
    ]
    return StatHistoryResponse(entries=entries, days=days)
