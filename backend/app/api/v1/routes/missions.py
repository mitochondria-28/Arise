import uuid

from fastapi import APIRouter, BackgroundTasks, Depends, Query
from fastapi import Response as FastAPIResponse
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user
from app.database.session import get_db
from app.models.mission_template import MissionTemplate
from app.models.user import User
from app.schemas.mission import (
    CheckinRequest,
    CheckinResponse,
    CreateMissionRequest,
    MissionListResponse,
    MissionLogListResponse,
    MissionResponse,
    UpdateMissionRequest,
)
from app.schemas.mission_template import MissionTemplateResponse
from app.services.ai_service import analyze_mission_bg
from app.services.mission_service import MissionService

router = APIRouter(prefix="/missions", tags=["missions"])


@router.get("/templates", response_model=list[MissionTemplateResponse])
async def list_mission_templates(
    category: str | None = Query(
        None,
        pattern="^(vitality|strength|intelligence|wisdom|charisma|discipline)$",
    ),
    frequency: str | None = Query(None, pattern="^(daily|weekly|monthly)$"),
    _: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    stmt = select(MissionTemplate).order_by(MissionTemplate.sort_order)
    if category:
        stmt = stmt.where(MissionTemplate.category == category)
    if frequency:
        stmt = stmt.where(MissionTemplate.frequency == frequency)
    result = await db.execute(stmt)
    return result.scalars().all()


@router.post("", response_model=MissionResponse, status_code=201)
async def create_mission(
    payload: CreateMissionRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await MissionService(db).create(
        current_user.id,
        title=payload.title,
        description=payload.description,
        category=payload.category,
        difficulty=payload.difficulty,
        frequency=payload.frequency,
        target_count=payload.target_count,
    )


@router.get("", response_model=MissionListResponse)
async def list_missions(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    status: str | None = Query(None, pattern="^(active|paused|completed|archived)$"),
    category: str | None = Query(
        None,
        pattern="^(vitality|strength|intelligence|wisdom|charisma|discipline)$",
    ),
    frequency: str | None = Query(None, pattern="^(daily|weekly|monthly)$"),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
):
    return await MissionService(db).list_for_user(
        current_user.id,
        status=status,
        category=category,
        frequency=frequency,
        page=page,
        page_size=page_size,
    )


@router.get("/{mission_id}", response_model=MissionResponse)
async def get_mission(
    mission_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await MissionService(db).get_by_id(mission_id, current_user.id)


@router.patch("/{mission_id}", response_model=MissionResponse)
async def update_mission(
    mission_id: uuid.UUID,
    payload: UpdateMissionRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await MissionService(db).update(
        mission_id,
        current_user.id,
        **payload.model_dump(exclude_none=True),
    )


@router.post("/{mission_id}/checkin", response_model=CheckinResponse)
async def checkin_mission(
    mission_id: uuid.UUID,
    payload: CheckinRequest,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await MissionService(db).checkin(
        mission_id,
        current_user.id,
        evidence_text=payload.evidence_text,
        reflection=payload.reflection,
        effort_level=payload.effort_level,
    )
    background_tasks.add_task(
        analyze_mission_bg,
        user_id=current_user.id,
        mission_id=mission_id,
        mission_title=result.mission.title,
        mission_category=result.mission.category,
        mission_frequency=result.mission.frequency,
        evidence_text=payload.evidence_text,
        reflection=payload.reflection,
        effort_level=payload.effort_level,
        xp_awarded=result.xp_awarded,
        streak_at_checkin=result.new_streak,
    )
    return result


@router.get("/{mission_id}/logs", response_model=MissionLogListResponse)
async def get_mission_logs(
    mission_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
):
    return await MissionService(db).get_logs(
        mission_id, current_user.id, page=page, page_size=page_size
    )


@router.delete("/{mission_id}", status_code=204)
async def archive_mission(
    mission_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await MissionService(db).archive(mission_id, current_user.id)
    return FastAPIResponse(status_code=204)
