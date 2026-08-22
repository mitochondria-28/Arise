import uuid
from datetime import datetime

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.exceptions import NotFoundError
from app.models.goal import Goal
from app.models.goal_completion import GoalCompletion


class GoalRepository:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_by_id(
        self,
        goal_id: uuid.UUID,
        *,
        user_id: uuid.UUID | None = None,
        load_completion: bool = True,
    ) -> Goal:
        """Get goal by ID. If user_id is provided, verifies ownership (raises NotFoundError if mismatch)."""
        stmt = select(Goal).where(Goal.id == goal_id)
        if load_completion:
            stmt = stmt.options(selectinload(Goal.completion))
        result = await self.db.execute(stmt)
        goal = result.scalar_one_or_none()

        if not goal or (user_id and goal.user_id != user_id):
            raise NotFoundError("Goal", str(goal_id))
        return goal

    async def list_by_user(
        self,
        user_id: uuid.UUID,
        *,
        status: str | None = None,
        category: str | None = None,
        page: int = 1,
        page_size: int = 20,
        load_completion: bool = True,
    ) -> tuple[list[Goal], int]:
        filters = [Goal.user_id == user_id]
        if status:
            filters.append(Goal.status == status)
        if category:
            filters.append(Goal.category == category)

        count_stmt = select(func.count()).select_from(Goal).where(*filters)
        total: int = (await self.db.execute(count_stmt)).scalar_one()

        stmt = (
            select(Goal)
            .where(*filters)
            .order_by(Goal.created_at.desc())
            .limit(page_size)
            .offset((page - 1) * page_size)
        )
        if load_completion:
            stmt = stmt.options(selectinload(Goal.completion))

        result = await self.db.execute(stmt)
        return list(result.scalars().all()), total

    async def create(
        self,
        *,
        user_id: uuid.UUID,
        title: str,
        category: str,
        difficulty: str,
        description: str | None = None,
        target_date: object = None,
    ) -> Goal:
        goal = Goal(
            user_id=user_id,
            title=title,
            description=description,
            category=category,
            difficulty=difficulty,
            target_date=target_date,
        )
        self.db.add(goal)
        await self.db.flush()
        await self.db.refresh(goal)
        return goal

    async def update(self, goal: Goal, **fields: object) -> Goal:
        for key, value in fields.items():
            setattr(goal, key, value)
        await self.db.flush()
        await self.db.refresh(goal)
        return goal


class GoalCompletionRepository:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def create(
        self,
        *,
        goal_id: uuid.UUID,
        evidence_text: str,
        effort_level: int,
        xp_awarded: int,
        reflection: str | None = None,
    ) -> GoalCompletion:
        completion = GoalCompletion(
            goal_id=goal_id,
            evidence_text=evidence_text,
            reflection=reflection,
            effort_level=effort_level,
            xp_awarded=xp_awarded,
        )
        self.db.add(completion)
        await self.db.flush()
        await self.db.refresh(completion)
        return completion
