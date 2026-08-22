from datetime import datetime, timedelta, timezone

import bcrypt
from jose import JWTError, jwt

from app.core.config import settings
from app.core.exceptions import UnauthorizedError


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt(rounds=12)).decode()


def verify_password(plain: str, hashed: str) -> bool:
    return bcrypt.checkpw(plain.encode(), hashed.encode())


def _make_token(subject: str, token_type: str, expires: timedelta) -> str:
    expire = datetime.now(timezone.utc) + expires
    return jwt.encode(
        {"sub": subject, "exp": expire, "type": token_type},
        settings.JWT_SECRET_KEY,
        algorithm=settings.JWT_ALGORITHM,
    )


def create_access_token(subject: str) -> str:
    return _make_token(
        subject,
        "access",
        timedelta(minutes=settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES),
    )


def create_refresh_token(subject: str) -> str:
    return _make_token(
        subject,
        "refresh",
        timedelta(days=settings.JWT_REFRESH_TOKEN_EXPIRE_DAYS),
    )


def verify_token(token: str, *, token_type: str = "access") -> str:
    """Decode and validate a JWT. Returns the subject (user UUID as string)."""
    try:
        payload = jwt.decode(
            token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM]
        )
    except JWTError:
        raise UnauthorizedError("Invalid or expired token.")

    if payload.get("type") != token_type:
        raise UnauthorizedError("Wrong token type.")

    sub: str | None = payload.get("sub")
    if not sub:
        raise UnauthorizedError("Token is missing subject.")

    return sub
