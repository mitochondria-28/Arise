import pytest
from jose import jwt

from app.core.config import settings
from app.core.exceptions import UnauthorizedError
from app.core.security import (
    create_access_token,
    create_refresh_token,
    hash_password,
    verify_password,
    verify_token,
)

USER_ID = "550e8400-e29b-41d4-a716-446655440000"


# ── Password hashing ───────────────────────────────────────────────────────────

def test_hash_password_is_not_plaintext():
    hashed = hash_password("securepassword")
    assert hashed != "securepassword"
    assert len(hashed) > 20


def test_verify_password_correct():
    hashed = hash_password("mypassword123")
    assert verify_password("mypassword123", hashed) is True


def test_verify_password_wrong():
    hashed = hash_password("mypassword123")
    assert verify_password("wrongpassword", hashed) is False


def test_two_hashes_of_same_password_differ():
    # bcrypt uses random salt — same input → different hash
    h1 = hash_password("same")
    h2 = hash_password("same")
    assert h1 != h2


# ── Token creation ─────────────────────────────────────────────────────────────

def test_create_access_token_returns_string():
    token = create_access_token(USER_ID)
    assert isinstance(token, str)
    assert len(token) > 0


def test_create_access_token_payload():
    token = create_access_token(USER_ID)
    payload = jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])
    assert payload["sub"] == USER_ID
    assert payload["type"] == "access"


def test_create_refresh_token_payload():
    token = create_refresh_token(USER_ID)
    payload = jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])
    assert payload["sub"] == USER_ID
    assert payload["type"] == "refresh"


# ── Token verification ─────────────────────────────────────────────────────────

def test_verify_access_token_returns_subject():
    token = create_access_token(USER_ID)
    assert verify_token(token, token_type="access") == USER_ID


def test_verify_refresh_token_returns_subject():
    token = create_refresh_token(USER_ID)
    assert verify_token(token, token_type="refresh") == USER_ID


def test_verify_access_token_as_refresh_raises():
    token = create_access_token(USER_ID)
    with pytest.raises(UnauthorizedError):
        verify_token(token, token_type="refresh")


def test_verify_refresh_token_as_access_raises():
    token = create_refresh_token(USER_ID)
    with pytest.raises(UnauthorizedError):
        verify_token(token, token_type="access")


def test_verify_garbage_token_raises():
    with pytest.raises(UnauthorizedError):
        verify_token("this.is.garbage", token_type="access")


def test_verify_tampered_token_raises():
    token = create_access_token(USER_ID)
    tampered = token[:-4] + "XXXX"
    with pytest.raises(UnauthorizedError):
        verify_token(tampered, token_type="access")
