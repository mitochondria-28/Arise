import uuid
from collections import defaultdict
from datetime import datetime, timedelta, timezone

from sqlalchemy import case, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.goal import Goal
from app.models.mission import Mission
from app.models.xp_transaction import XPTransaction


class StatsRepository:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_goal_summary(self, user_id: uuid.UUID) -> dict:
        stmt = (
            select(
                Goal.difficulty,
                Goal.category,
                func.count().label("n"),
            )
            .where(Goal.user_id == user_id, Goal.status == "completed")
            .group_by(Goal.difficulty, Goal.category)
        )
        rows = (await self.db.execute(stmt)).all()

        by_difficulty: dict[str, int] = defaultdict(int)
        by_category: dict[str, int] = defaultdict(int)
        total = 0

        for row in rows:
            by_difficulty[row.difficulty] += row.n
            by_category[row.category] += row.n
            total += row.n

        return {
            "total_goals_completed": total,
            "goals_by_difficulty": dict(by_difficulty),
            "goals_by_category": dict(by_category),
        }

    async def get_mission_summary(self, user_id: uuid.UUID) -> dict:
        agg_stmt = select(
            func.count().filter(Mission.status == "active").label("active_count"),
            func.coalesce(func.sum(Mission.completion_count), 0).label("total_checkins"),
            func.coalesce(func.max(Mission.longest_streak), 0).label("best_streak"),
            func.coalesce(func.max(Mission.current_streak), 0).label("current_streak_max"),
        ).where(Mission.user_id == user_id)

        row = (await self.db.execute(agg_stmt)).one()

        top_stmt = (
            select(Mission)
            .where(Mission.user_id == user_id, Mission.status == "active")
            .order_by(Mission.current_streak.desc())
            .limit(5)
        )
        top_missions = list((await self.db.execute(top_stmt)).scalars())

        return {
            "missions_active": int(row.active_count or 0),
            "total_checkins": int(row.total_checkins or 0),
            "best_streak": int(row.best_streak or 0),
            "current_streak_max": int(row.current_streak_max or 0),
            "top_missions": [
                {
                    "title": m.title,
                    "current_streak": m.current_streak,
                    "longest_streak": m.longest_streak,
                    "completion_count": m.completion_count,
                    "frequency": m.frequency,
                }
                for m in top_missions
            ],
        }

    async def get_xp_history(
        self, character_id: uuid.UUID, *, days: int = 30
    ) -> dict:
        since = datetime.now(tz=timezone.utc) - timedelta(days=days)

        stmt = (
            select(
                func.date_trunc("day", XPTransaction.created_at).label("day"),
                func.sum(XPTransaction.amount).label("total"),
                func.sum(
                    case(
                        (XPTransaction.source_type == "goal", XPTransaction.amount),
                        else_=0,
                    )
                ).label("goal_xp"),
                func.sum(
                    case(
                        (XPTransaction.source_type == "mission", XPTransaction.amount),
                        else_=0,
                    )
                ).label("mission_xp"),
            )
            .where(
                XPTransaction.character_id == character_id,
                XPTransaction.created_at >= since,
            )
            .group_by("day")
            .order_by("day")
        )

        rows = (await self.db.execute(stmt)).all()
        entries = []
        total_in_period = 0

        for row in rows:
            xp = int(row.total or 0)
            total_in_period += xp
            entries.append({
                "date": row.day.date().isoformat(),
                "xp": xp,
                "goal_xp": int(row.goal_xp or 0),
                "mission_xp": int(row.mission_xp or 0),
            })

        return {
            "entries": entries,
            "total_xp_in_period": total_in_period,
            "days": days,
        }
