from sqlalchemy import Boolean, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base import Base, TimestampMixin, UUIDMixin


class User(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "users"

    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    profile: Mapped["UserProfile"] = relationship(  # type: ignore[name-defined]
        "UserProfile", back_populates="user", uselist=False, cascade="all, delete-orphan"
    )
    character: Mapped["Character"] = relationship(  # type: ignore[name-defined]
        "Character", back_populates="user", uselist=False, cascade="all, delete-orphan"
    )
    goals: Mapped[list["Goal"]] = relationship(  # type: ignore[name-defined]
        "Goal", back_populates="user", cascade="all, delete-orphan"
    )
    missions: Mapped[list["Mission"]] = relationship(  # type: ignore[name-defined]
        "Mission", back_populates="user", cascade="all, delete-orphan"
    )

    def __repr__(self) -> str:
        return f"<User id={self.id} email={self.email}>"
