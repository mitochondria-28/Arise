import uuid
from datetime import date, datetime, timedelta, timezone

from sqlalchemy import select, func
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.gemini import gemini_client
from app.models.ai_conversation import AIConversation, AIMessage
from app.models.character import Character
from app.models.goal import Goal
from app.models.goal_completion import GoalCompletion
from app.models.journal import JournalEntry
from app.models.mission import Mission
from app.models.mission_log import MissionLog
from app.models.user_profile import UserProfile
from app.models.weekly_review import WeeklyReview
from app.models.xp_transaction import XPTransaction


class CoachService:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db

    async def _display_name(self, user_id: uuid.UUID) -> str:
        result = await self._db.execute(
            select(UserProfile).where(UserProfile.user_id == user_id)
        )
        profile = result.scalar_one_or_none()
        return profile.display_name if (profile and profile.display_name) else "Hunter"

    async def _context_summary(self, user_id: uuid.UUID) -> str:
        char_result = await self._db.execute(
            select(Character)
            .options(selectinload(Character.stats))
            .where(Character.user_id == user_id)
        )
        character = char_result.scalar_one_or_none()

        goals_result = await self._db.execute(
            select(Goal)
            .where(Goal.user_id == user_id, Goal.status == "active")
            .limit(5)
        )
        active_goals = [g.title for g in goals_result.scalars()]

        missions_result = await self._db.execute(
            select(Mission)
            .where(Mission.user_id == user_id, Mission.status == "active")
            .order_by(Mission.current_streak.desc())
            .limit(5)
        )
        top_missions = [
            f"{m.title} (streak: {m.current_streak})"
            for m in missions_result.scalars()
        ]

        parts = []
        if character:
            parts.append(f"Level {character.level} {character.rank}, {character.total_xp} XP")
            if character.stats:
                s = character.stats
                parts.append(
                    f"Stats: VIT={s.vitality} STR={s.strength} INT={s.intelligence} "
                    f"WIS={s.wisdom} CHA={s.charisma} DIS={s.discipline}"
                )
        if active_goals:
            parts.append("Active goals: " + ", ".join(active_goals))
        if top_missions:
            parts.append("Top missions: " + ", ".join(top_missions))

        return " | ".join(parts) if parts else "No character data yet."

    # ── Conversations ──────────────────────────────────────────────────────────

    async def list_conversations(self, user_id: uuid.UUID) -> list[AIConversation]:
        result = await self._db.execute(
            select(AIConversation)
            .where(AIConversation.user_id == user_id)
            .order_by(AIConversation.updated_at.desc())
            .limit(50)
        )
        return list(result.scalars())

    async def create_conversation(
        self, user_id: uuid.UUID, title: str = "New Conversation"
    ) -> AIConversation:
        now = datetime.now(timezone.utc)
        conv = AIConversation(
            id=uuid.uuid4(),
            user_id=user_id,
            title=title,
            created_at=now,
            updated_at=now,
        )
        self._db.add(conv)
        await self._db.commit()
        await self._db.refresh(conv)
        return conv

    async def get_conversation(
        self, conversation_id: uuid.UUID, user_id: uuid.UUID
    ) -> AIConversation | None:
        result = await self._db.execute(
            select(AIConversation)
            .options(selectinload(AIConversation.messages))
            .where(
                AIConversation.id == conversation_id,
                AIConversation.user_id == user_id,
            )
        )
        return result.scalar_one_or_none()

    async def send_message(
        self,
        conversation_id: uuid.UUID,
        user_id: uuid.UUID,
        user_text: str,
    ) -> AIMessage:
        conv = await self.get_conversation(conversation_id, user_id)
        if conv is None:
            raise ValueError("Conversation not found.")

        now = datetime.now(timezone.utc)

        user_msg = AIMessage(
            id=uuid.uuid4(),
            conversation_id=conversation_id,
            role="user",
            content=user_text,
            created_at=now,
        )
        self._db.add(user_msg)
        await self._db.flush()

        history = [
            {"role": m.role, "text": m.content}
            for m in conv.messages
        ]
        history.append({"role": "user", "text": user_text})

        context_summary = await self._context_summary(user_id)
        prompt_with_context = gemini_client.build_coach_reply_prompt(
            user_message=user_text,
            context_summary=context_summary,
        )
        history[-1] = {"role": "user", "text": prompt_with_context}

        reply_text = await gemini_client.generate_chat(history)
        if not reply_text:
            reply_text = "I'm having trouble connecting right now. Please try again."

        ai_msg = AIMessage(
            id=uuid.uuid4(),
            conversation_id=conversation_id,
            role="model",
            content=reply_text,
            created_at=datetime.now(timezone.utc),
        )
        self._db.add(ai_msg)

        # Update conversation title from first user message
        if conv.title == "New Conversation":
            conv.title = user_text[:60] + ("…" if len(user_text) > 60 else "")
        conv.updated_at = datetime.now(timezone.utc)

        await self._db.commit()
        await self._db.refresh(ai_msg)
        return ai_msg

    # ── Weekly Review ──────────────────────────────────────────────────────────

    @staticmethod
    def _current_week_bounds() -> tuple[date, date]:
        today = date.today()
        week_start = today - timedelta(days=today.weekday())  # Monday
        week_end = week_start + timedelta(days=6)              # Sunday
        return week_start, week_end

    async def get_or_generate_weekly_review(self, user_id: uuid.UUID) -> WeeklyReview | None:
        week_start, week_end = self._current_week_bounds()

        existing = (
            await self._db.execute(
                select(WeeklyReview).where(
                    WeeklyReview.user_id == user_id,
                    WeeklyReview.week_start == week_start,
                )
            )
        ).scalar_one_or_none()
        if existing:
            return existing

        # Gather this week's stats
        display_name = await self._display_name(user_id)

        week_start_dt = datetime(week_start.year, week_start.month, week_start.day, tzinfo=timezone.utc)
        week_end_dt = datetime(week_end.year, week_end.month, week_end.day, 23, 59, 59, tzinfo=timezone.utc)

        xp_row = await self._db.execute(
            select(func.coalesce(func.sum(XPTransaction.amount), 0))
            .where(
                XPTransaction.character_id.in_(
                    select(Character.id).where(Character.user_id == user_id)
                ),
                XPTransaction.created_at >= week_start_dt,
                XPTransaction.created_at <= week_end_dt,
            )
        )
        xp_earned = xp_row.scalar() or 0

        goals_count = (
            await self._db.execute(
                select(func.count()).select_from(GoalCompletion).join(
                    Goal, Goal.id == GoalCompletion.goal_id
                ).where(
                    Goal.user_id == user_id,
                    Goal.completed_at >= week_start_dt,
                    Goal.completed_at <= week_end_dt,
                )
            )
        ).scalar() or 0

        checkins_count = (
            await self._db.execute(
                select(func.count()).select_from(MissionLog).join(
                    Mission, Mission.id == MissionLog.mission_id
                ).where(
                    Mission.user_id == user_id,
                    MissionLog.created_at >= week_start_dt,
                    MissionLog.created_at <= week_end_dt,
                )
            )
        ).scalar() or 0

        journal_count = (
            await self._db.execute(
                select(func.count()).select_from(JournalEntry).where(
                    JournalEntry.user_id == user_id,
                    JournalEntry.created_at >= week_start_dt,
                    JournalEntry.created_at <= week_end_dt,
                )
            )
        ).scalar() or 0

        best_streak_row = await self._db.execute(
            select(func.coalesce(func.max(Mission.current_streak), 0))
            .where(Mission.user_id == user_id)
        )
        best_streak = best_streak_row.scalar() or 0

        prompt = gemini_client.build_weekly_review_prompt(
            display_name=display_name,
            week_label=f"{week_start.isoformat()} – {week_end.isoformat()}",
            xp_earned=xp_earned,
            goals_completed=goals_count,
            mission_checkins=checkins_count,
            best_streak=best_streak,
            skills_practiced=0,
            journal_entries=journal_count,
            mood_avg=None,
            top_categories=[],
        )

        content = await gemini_client.generate(prompt)
        if not content:
            return None

        review = WeeklyReview(
            id=uuid.uuid4(),
            user_id=user_id,
            week_start=week_start,
            week_end=week_end,
            content=content,
            model_used=settings.GEMINI_MODEL,
            created_at=datetime.now(timezone.utc),
        )
        self._db.add(review)
        await self._db.commit()
        await self._db.refresh(review)
        return review

    async def list_weekly_reviews(self, user_id: uuid.UUID) -> list[WeeklyReview]:
        result = await self._db.execute(
            select(WeeklyReview)
            .where(WeeklyReview.user_id == user_id)
            .order_by(WeeklyReview.week_start.desc())
            .limit(12)
        )
        return list(result.scalars())
