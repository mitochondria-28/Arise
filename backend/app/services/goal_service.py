import uuid
from datetime import datetime, timezone

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import ConflictError, ValidationError
from app.core.xp_engine import GOAL_DIFFICULTIES, STAT_CATEGORIES, calculate_goal_xp
from app.models.goal import Goal
from app.repositories.character_repository import CharacterRepository
from app.repositories.goal_repository import GoalCompletionRepository, GoalRepository
from app.schemas.goal import CompleteGoalResponse, GoalListResponse, GoalResponse
from app.services.character_service import CharacterService


class GoalService:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db
        self._goals = GoalRepository(db)
        self._completions = GoalCompletionRepository(db)

    async def create(
        self,
        user_id: uuid.UUID,
        *,
        title: str,
        category: str,
        difficulty: str,
        description: str | None = None,
        target_date: object = None,
    ) -> Goal:
        if category not in STAT_CATEGORIES:
            raise ValidationError(f"Unknown category: {category!r}.")
        if difficulty not in GOAL_DIFFICULTIES:
            raise ValidationError(f"Unknown difficulty: {difficulty!r}.")

        goal = await self._goals.create(
            user_id=user_id,
            title=title,
            description=description,
            category=category,
            difficulty=difficulty,
            target_date=target_date,
        )
        # Reload with completion relationship initialised (None for new goals)
        return await self._goals.get_by_id(goal.id, user_id=user_id, load_completion=True)

    async def list_for_user(
        self,
        user_id: uuid.UUID,
        *,
        status: str | None = None,
        category: str | None = None,
        page: int = 1,
        page_size: int = 20,
    ) -> GoalListResponse:
        goals, total = await self._goals.list_by_user(
            user_id,
            status=status,
            category=category,
            page=page,
            page_size=page_size,
        )
        return GoalListResponse(
            goals=[GoalResponse.model_validate(g) for g in goals],
            total=total,
            page=page,
            page_size=page_size,
        )

    async def get_by_id(self, goal_id: uuid.UUID, user_id: uuid.UUID) -> Goal:
        return await self._goals.get_by_id(goal_id, user_id=user_id, load_completion=True)

    async def update(
        self,
        goal_id: uuid.UUID,
        user_id: uuid.UUID,
        **fields: object,
    ) -> Goal:
        goal = await self._goals.get_by_id(goal_id, user_id=user_id)

        # Block status changes on completed goals
        new_status = fields.get("status")
        if new_status and goal.status == "completed":
            raise ConflictError("A completed goal's status cannot be changed.")
        if new_status and goal.status == "archived":
            raise ConflictError("An archived goal must be restored before changing status.")

        # Remove None values so existing data isn't overwritten
        updates = {k: v for k, v in fields.items() if v is not None}
        if not updates:
            return await self._goals.get_by_id(goal_id, user_id=user_id, load_completion=True)

        await self._goals.update(goal, **updates)
        return await self._goals.get_by_id(goal_id, user_id=user_id, load_completion=True)

    async def complete(
        self,
        goal_id: uuid.UUID,
        user_id: uuid.UUID,
        *,
        evidence_text: str,
        reflection: str | None,
        effort_level: int,
    ) -> CompleteGoalResponse:
        goal = await self._goals.get_by_id(goal_id, user_id=user_id)

        if goal.status != "active":
            raise ConflictError(
                f"Only active goals can be completed (current status: '{goal.status}')."
            )

        xp_awarded = calculate_goal_xp(goal.difficulty, effort_level)

        await self._completions.create(
            goal_id=goal_id,
            evidence_text=evidence_text,
            reflection=reflection,
            effort_level=effort_level,
            xp_awarded=xp_awarded,
        )

        now = datetime.now(timezone.utc)
        await self._goals.update(goal, status="completed", completed_at=now)

        character = await CharacterRepository(self._db).get_by_user_id(user_id)
        levels_gained: list[int] = []
        if character:
            _, levels_gained = await CharacterService(self._db).award_xp(
                character.id,
                xp_awarded,
                "goal",
                source_id=goal_id,
                stat_category=goal.category,
                description=f"Completed goal: {goal.title}",
            )

        completed_goal = await self._goals.get_by_id(
            goal_id, user_id=user_id, load_completion=True
        )
        return CompleteGoalResponse(
            goal=GoalResponse.model_validate(completed_goal),
            xp_awarded=xp_awarded,
            levels_gained=levels_gained,
        )

    async def archive(self, goal_id: uuid.UUID, user_id: uuid.UUID) -> None:
        goal = await self._goals.get_by_id(goal_id, user_id=user_id)
        if goal.status != "archived":
            await self._goals.update(goal, status="archived")
