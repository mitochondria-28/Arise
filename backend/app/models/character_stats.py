import uuid

from sqlalchemy import ForeignKey, Integer
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base import Base, TimestampMixin, UUIDMixin


class CharacterStats(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "character_stats"

    character_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("characters.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
        index=True,
    )
    vitality: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    strength: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    intelligence: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    wisdom: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    charisma: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    discipline: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    character: Mapped["Character"] = relationship(  # type: ignore[name-defined]
        "Character", back_populates="stats"
    )

    def __repr__(self) -> str:
        return f"<CharacterStats character_id={self.character_id}>"
