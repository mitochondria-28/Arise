import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class ProfileResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    display_name: str
    avatar_url: str | None
    bio: str | None
    timezone: str
    theme_preference: str


class UpdateProfileRequest(BaseModel):
    display_name: str | None = Field(None, min_length=1, max_length=100)
    bio: str | None = Field(None, max_length=500)
    timezone: str | None = Field(None, max_length=100)
    theme_preference: str | None = Field(None, pattern="^(dark|light|system)$")


class ChangePasswordRequest(BaseModel):
    current_password: str = Field(..., min_length=1)
    new_password: str = Field(..., min_length=8)


class DeleteAccountRequest(BaseModel):
    password: str = Field(..., min_length=1)


class MeResponse(BaseModel):
    """Full user detail returned from GET /users/me."""
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    email: str
    is_active: bool
    is_verified: bool
    created_at: datetime
    profile: ProfileResponse | None = None
