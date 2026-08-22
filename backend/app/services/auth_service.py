from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import ConflictError, UnauthorizedError
from app.core.security import (
    create_access_token,
    create_refresh_token,
    hash_password,
    verify_password,
    verify_token,
)
from app.repositories.user_repository import UserProfileRepository, UserRepository
from app.schemas.auth import TokenPair
from app.services.character_service import CharacterService


class AuthService:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db
        self._users = UserRepository(db)
        self._profiles = UserProfileRepository(db)

    async def register(self, *, email: str, password: str) -> TokenPair:
        if await self._users.get_by_email(email):
            raise ConflictError(f"An account with email '{email}' already exists.")

        user = await self._users.create(
            email=email,
            hashed_password=hash_password(password),
        )

        display_name = email.split("@")[0]
        await self._profiles.create(user_id=user.id, display_name=display_name)
        await CharacterService(self._db).create_for_user(user.id)

        subject = str(user.id)
        return TokenPair(
            access_token=create_access_token(subject),
            refresh_token=create_refresh_token(subject),
        )

    async def login(self, *, email: str, password: str) -> TokenPair:
        user = await self._users.get_by_email(email)

        # Intentionally vague error to avoid user enumeration
        if not user or not verify_password(password, user.hashed_password):
            raise UnauthorizedError("Invalid email or password.")

        if not user.is_active:
            raise UnauthorizedError("This account has been disabled.")

        subject = str(user.id)
        return TokenPair(
            access_token=create_access_token(subject),
            refresh_token=create_refresh_token(subject),
        )

    async def refresh(self, *, refresh_token: str) -> TokenPair:
        user_id_str = verify_token(refresh_token, token_type="refresh")
        import uuid
        user = await self._users.get_by_id(uuid.UUID(user_id_str))
        if not user or not user.is_active:
            raise UnauthorizedError()

        subject = str(user.id)
        return TokenPair(
            access_token=create_access_token(subject),
            refresh_token=create_refresh_token(subject),
        )
