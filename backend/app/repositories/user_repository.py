import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.user import User
from app.models.user_profile import UserProfile


class UserRepository:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_by_id(self, user_id: uuid.UUID, *, load_profile: bool = False) -> User | None:
        stmt = select(User).where(User.id == user_id)
        if load_profile:
            stmt = stmt.options(selectinload(User.profile))
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def get_by_email(self, email: str) -> User | None:
        result = await self.db.execute(select(User).where(User.email == email))
        return result.scalar_one_or_none()

    async def create(self, *, email: str, hashed_password: str) -> User:
        user = User(email=email, hashed_password=hashed_password)
        self.db.add(user)
        await self.db.flush()       # Assigns user.id without committing
        await self.db.refresh(user) # Loads server-generated timestamps
        return user

    async def update_password(self, user: User, hashed_password: str) -> None:
        user.hashed_password = hashed_password
        await self.db.flush()

    async def deactivate(self, user: User) -> None:
        user.is_active = False
        await self.db.flush()


class UserProfileRepository:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def create(self, *, user_id: uuid.UUID, display_name: str) -> UserProfile:
        profile = UserProfile(user_id=user_id, display_name=display_name)
        self.db.add(profile)
        await self.db.flush()
        await self.db.refresh(profile)
        return profile

    async def update(self, profile: UserProfile, **fields: object) -> UserProfile:
        for key, value in fields.items():
            if value is not None:
                setattr(profile, key, value)
        await self.db.flush()
        await self.db.refresh(profile)
        return profile
