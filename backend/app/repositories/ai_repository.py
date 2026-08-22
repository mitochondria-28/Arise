import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.ai_analysis import AIAnalysis


class AIAnalysisRepository:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db

    async def create(
        self,
        *,
        character_id: uuid.UUID,
        source_type: str,
        source_id: uuid.UUID | None,
        prompt: str,
        content: str,
        model_used: str,
    ) -> AIAnalysis:
        analysis = AIAnalysis(
            character_id=character_id,
            source_type=source_type,
            source_id=source_id,
            prompt=prompt,
            content=content,
            model_used=model_used,
        )
        self._db.add(analysis)
        await self._db.flush()
        await self._db.refresh(analysis)
        return analysis

    async def get_latest_by_source(
        self,
        *,
        source_type: str,
        source_id: uuid.UUID,
    ) -> AIAnalysis | None:
        result = await self._db.execute(
            select(AIAnalysis)
            .where(
                AIAnalysis.source_type == source_type,
                AIAnalysis.source_id == source_id,
            )
            .order_by(AIAnalysis.created_at.desc())
            .limit(1)
        )
        return result.scalar_one_or_none()

    async def get_latest_growth_report(
        self, character_id: uuid.UUID
    ) -> AIAnalysis | None:
        result = await self._db.execute(
            select(AIAnalysis)
            .where(
                AIAnalysis.character_id == character_id,
                AIAnalysis.source_type == "growth_report",
            )
            .order_by(AIAnalysis.created_at.desc())
            .limit(1)
        )
        return result.scalar_one_or_none()
