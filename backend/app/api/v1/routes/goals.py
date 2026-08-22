import uuid

from fastapi import APIRouter, BackgroundTasks, Depends, Query
from fastapi import Response as FastAPIResponse
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user
from app.core.exceptions import NotFoundError
from app.database.session import get_db
from app.models.goal_milestone import GoalMilestone
from app.models.goal_template import GoalTemplate
from app.models.user import User
from app.schemas.goal import (
    CompleteGoalRequest,
    CompleteGoalResponse,
    CreateGoalRequest,
    GoalListResponse,
    GoalResponse,
    UpdateGoalRequest,
)
from app.schemas.goal_milestone import (
    CreateMilestoneRequest,
    GoalMilestoneResponse,
    UpdateMilestoneRequest,
)
from app.schemas.goal_template import GoalTemplateResponse
from app.services.ai_service import analyze_goal_bg
from app.services.goal_service import GoalService

router = APIRouter(prefix="/goals", tags=["goals"])


@router.post("", response_model=GoalResponse, status_code=201)
async def create_goal(
    payload: CreateGoalRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = GoalService(db)
    return await service.create(
        current_user.id,
        title=payload.title,
        description=payload.description,
        category=payload.category,
        difficulty=payload.difficulty,
        target_date=payload.target_date,
    )


@router.get("", response_model=GoalListResponse)
async def list_goals(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    status: str | None = Query(None, pattern="^(active|completed|abandoned|archived)$"),
    category: str | None = Query(
        None,
        pattern="^(vitality|strength|intelligence|wisdom|charisma|discipline)$",
    ),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
):
    return await GoalService(db).list_for_user(
        current_user.id,
        status=status,
        category=category,
        page=page,
        page_size=page_size,
    )


@router.get("/templates", response_model=list[GoalTemplateResponse])
async def list_templates(
    category: str | None = Query(
        None,
        pattern="^(vitality|strength|intelligence|wisdom|charisma|discipline)$",
    ),
    _: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    stmt = select(GoalTemplate).order_by(GoalTemplate.sort_order)
    if category:
        stmt = stmt.where(GoalTemplate.category == category)
    result = await db.execute(stmt)
    return result.scalars().all()


@router.get("/{goal_id}", response_model=GoalResponse)
async def get_goal(
    goal_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await GoalService(db).get_by_id(uuid.UUID(goal_id), current_user.id)


@router.patch("/{goal_id}", response_model=GoalResponse)
async def update_goal(
    goal_id: str,
    payload: UpdateGoalRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await GoalService(db).update(
        uuid.UUID(goal_id),
        current_user.id,
        **payload.model_dump(exclude_none=True),
    )


@router.post("/{goal_id}/complete", response_model=CompleteGoalResponse)
async def complete_goal(
    goal_id: str,
    payload: CompleteGoalRequest,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    gid = uuid.UUID(goal_id)
    result = await GoalService(db).complete(
        gid,
        current_user.id,
        evidence_text=payload.evidence_text,
        reflection=payload.reflection,
        effort_level=payload.effort_level,
    )
    background_tasks.add_task(
        analyze_goal_bg,
        user_id=current_user.id,
        goal_id=gid,
        goal_title=result.goal.title,
        goal_category=result.goal.category,
        goal_difficulty=result.goal.difficulty,
        evidence_text=payload.evidence_text,
        reflection=payload.reflection,
        effort_level=payload.effort_level,
        xp_awarded=result.xp_awarded,
    )
    return result


@router.delete("/{goal_id}", status_code=204)
async def archive_goal(
    goal_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await GoalService(db).archive(uuid.UUID(goal_id), current_user.id)
    return FastAPIResponse(status_code=204)


# ── Goal Milestones ────────────────────────────────────────────────────────────

async def _verify_goal_owner(goal_id: uuid.UUID, user_id: uuid.UUID, db: AsyncSession) -> None:
    from app.models.goal import Goal
    result = await db.execute(
        select(Goal).where(Goal.id == goal_id, Goal.user_id == user_id)
    )
    if not result.scalar_one_or_none():
        raise NotFoundError("Goal", str(goal_id))


@router.get("/{goal_id}/milestones", response_model=list[GoalMilestoneResponse])
async def list_milestones(
    goal_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    gid = uuid.UUID(goal_id)
    await _verify_goal_owner(gid, current_user.id, db)
    result = await db.execute(
        select(GoalMilestone)
        .where(GoalMilestone.goal_id == gid)
        .order_by(GoalMilestone.sort_order, GoalMilestone.created_at)
    )
    return result.scalars().all()


@router.post("/{goal_id}/milestones", response_model=GoalMilestoneResponse, status_code=201)
async def create_milestone(
    goal_id: str,
    payload: CreateMilestoneRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    gid = uuid.UUID(goal_id)
    await _verify_goal_owner(gid, current_user.id, db)
    ms = GoalMilestone(
        goal_id=gid,
        title=payload.title,
        description=payload.description,
        sort_order=payload.sort_order,
    )
    db.add(ms)
    await db.commit()
    await db.refresh(ms)
    return ms


@router.patch("/{goal_id}/milestones/{milestone_id}", response_model=GoalMilestoneResponse)
async def update_milestone(
    goal_id: str,
    milestone_id: str,
    payload: UpdateMilestoneRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    gid = uuid.UUID(goal_id)
    await _verify_goal_owner(gid, current_user.id, db)
    result = await db.execute(
        select(GoalMilestone).where(
            GoalMilestone.id == uuid.UUID(milestone_id),
            GoalMilestone.goal_id == gid,
        )
    )
    ms = result.scalar_one_or_none()
    if not ms:
        raise NotFoundError("GoalMilestone", milestone_id)
    for field, value in payload.model_dump(exclude_none=True).items():
        setattr(ms, field, value)
    await db.commit()
    await db.refresh(ms)
    return ms


@router.delete("/{goal_id}/milestones/{milestone_id}", status_code=204)
async def delete_milestone(
    goal_id: str,
    milestone_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    gid = uuid.UUID(goal_id)
    await _verify_goal_owner(gid, current_user.id, db)
    result = await db.execute(
        select(GoalMilestone).where(
            GoalMilestone.id == uuid.UUID(milestone_id),
            GoalMilestone.goal_id == gid,
        )
    )
    ms = result.scalar_one_or_none()
    if not ms:
        raise NotFoundError("GoalMilestone", milestone_id)
    await db.delete(ms)
    await db.commit()
    return FastAPIResponse(status_code=204)
