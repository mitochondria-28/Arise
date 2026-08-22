import uuid
from datetime import date, datetime

from sqlalchemy import Date, DateTime, ForeignKey, Integer
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base import Base, UUIDMixin


class StatSnapshot(UUIDMixin, Base):
    __tablename__ = "stat_snapshots"

    character_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("characters.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    snapshot_date: Mapped[date] = mapped_column(Date, nullable=False)
    vitality:     Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    strength:     Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    intelligence: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    wisdom:       Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    charisma:     Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    discipline:   Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    total_xp:     Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    level:        Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )

    character: Mapped["Character"] = relationship("Character")  # type: ignore[name-defined]
