from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy import String, Text, Integer

from app.database.base import Base, UUIDMixin


class MissionTemplate(UUIDMixin, Base):
    __tablename__ = "mission_templates"

    title: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    category: Mapped[str] = mapped_column(String(50), nullable=False)
    difficulty: Mapped[str] = mapped_column(String(20), nullable=False)
    frequency: Mapped[str] = mapped_column(String(20), nullable=False)
    emoji: Mapped[str] = mapped_column(String(10), nullable=False, default="⚡")
    sort_order: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
