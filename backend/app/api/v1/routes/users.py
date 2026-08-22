from fastapi import APIRouter, Depends, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user
from app.core.exceptions import UnauthorizedError, ValidationError
from app.core.security import hash_password, verify_password
from app.database.session import get_db
from app.models.user import User
from app.repositories.user_repository import UserProfileRepository, UserRepository
from app.schemas.user import (
    ChangePasswordRequest,
    DeleteAccountRequest,
    MeResponse,
    UpdateProfileRequest,
)

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me", response_model=MeResponse)
async def get_me(current_user: User = Depends(get_current_user)):
    return current_user


@router.patch("/me/profile", response_model=MeResponse)
async def update_my_profile(
    payload: UpdateProfileRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if current_user.profile:
        updates = payload.model_dump(exclude_none=True)
        if updates:
            await UserProfileRepository(db).update(current_user.profile, **updates)
    return current_user


@router.post("/me/change-password", status_code=status.HTTP_204_NO_CONTENT)
async def change_password(
    payload: ChangePasswordRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if not verify_password(payload.current_password, current_user.hashed_password):
        raise ValidationError("Current password is incorrect.")
    new_hash = hash_password(payload.new_password)
    await UserRepository(db).update_password(current_user, new_hash)


@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT)
async def delete_account(
    payload: DeleteAccountRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if not verify_password(payload.password, current_user.hashed_password):
        raise UnauthorizedError("Password is incorrect.")
    await UserRepository(db).deactivate(current_user)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
