from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user
from app.database.session import get_db
from app.models.user import User
from app.schemas.achievement import AchievementResponse, SyncResponse
from app.services.achievement_service import AchievementService

router = APIRouter(prefix="/achievements", tags=["achievements"])


def _to_schema(ach, unlocked_at: str | None) -> AchievementResponse:
    return AchievementResponse(
        key=ach.key,
        title=ach.title,
        description=ach.description,
        icon=ach.icon,
        category=ach.category,
        threshold=ach.threshold,
        unlocked_at=unlocked_at,
    )


@router.get("", response_model=list[AchievementResponse])
async def list_achievements(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Return all achievements with the user's unlock status."""
    service = AchievementService(db)
    items = await service.list_with_status(current_user.id)
    return [_to_schema(ach, unlocked_at) for ach, unlocked_at in items]


@router.post("/sync", response_model=SyncResponse)
async def sync_achievements(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Check the user's current state against all achievement definitions.
    Awards any newly earned achievements and returns them.
    Call this after completing a goal or mission check-in.
    """
    service = AchievementService(db)
    newly_unlocked = await service.sync(current_user.id)
    all_items = await service.list_with_status(current_user.id)
    total = sum(1 for _, ua in all_items if ua is not None)

    return SyncResponse(
        newly_unlocked=[_to_schema(ach, ua) for ach, ua in newly_unlocked],
        total_unlocked=total,
    )
