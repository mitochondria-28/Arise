import uuid

from sqlalchemy import ForeignKey, Integer, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base import Base, TimestampMixin, UUIDMixin


class Character(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "characters"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
        index=True,
    )
    title: Mapped[str] = mapped_column(String(100), default="The Awakened", nullable=False)
    level: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    total_xp: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    current_level_xp: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    rank: Mapped[str] = mapped_column(String(5), default="E", nullable=False)

    user: Mapped["User"] = relationship(  # type: ignore[name-defined]
        "User", back_populates="character"
    )
    stats: Mapped["CharacterStats"] = relationship(  # type: ignore[name-defined]
        "CharacterStats",
        back_populates="character",
        uselist=False,
        cascade="all, delete-orphan",
    )
    xp_transactions: Mapped[list["XPTransaction"]] = relationship(  # type: ignore[name-defined]
        "XPTransaction",
        back_populates="character",
        cascade="all, delete-orphan",
    )

    def __repr__(self) -> str:
        return f"<Character user_id={self.user_id} level={self.level} rank={self.rank!r}>"
