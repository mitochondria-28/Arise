import pytest
from httpx import AsyncClient


# ── Register ───────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_register_success(client: AsyncClient):
    r = await client.post("/api/v1/auth/register", json={
        "email": "arise_test@example.com",
        "password": "StrongPass1!",
    })
    assert r.status_code == 201
    data = r.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"


@pytest.mark.asyncio
async def test_register_duplicate_email(client: AsyncClient):
    payload = {"email": "duplicate@example.com", "password": "Password123!"}
    await client.post("/api/v1/auth/register", json=payload)
    r = await client.post("/api/v1/auth/register", json=payload)
    assert r.status_code == 409
    assert "already exists" in r.json()["error"]["message"]


@pytest.mark.asyncio
async def test_register_short_password(client: AsyncClient):
    r = await client.post("/api/v1/auth/register", json={
        "email": "short@example.com",
        "password": "abc",
    })
    assert r.status_code == 422


@pytest.mark.asyncio
async def test_register_invalid_email(client: AsyncClient):
    r = await client.post("/api/v1/auth/register", json={
        "email": "not-an-email",
        "password": "ValidPass1!",
    })
    assert r.status_code == 422


# ── Login ──────────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_login_success(client: AsyncClient):
    email, password = "login_test@example.com", "LoginPass1!"
    await client.post("/api/v1/auth/register", json={"email": email, "password": password})

    r = await client.post("/api/v1/auth/login", json={"email": email, "password": password})
    assert r.status_code == 200
    data = r.json()
    assert "access_token" in data
    assert "refresh_token" in data


@pytest.mark.asyncio
async def test_login_wrong_password(client: AsyncClient):
    email = "wrongpass@example.com"
    await client.post("/api/v1/auth/register", json={"email": email, "password": "CorrectPass1!"})

    r = await client.post("/api/v1/auth/login", json={"email": email, "password": "WrongPass1!"})
    assert r.status_code == 401
    assert "Invalid" in r.json()["error"]["message"]


@pytest.mark.asyncio
async def test_login_nonexistent_user(client: AsyncClient):
    r = await client.post("/api/v1/auth/login", json={
        "email": "ghost@example.com",
        "password": "AnyPass123!",
    })
    assert r.status_code == 401


# ── Refresh ────────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_refresh_success(client: AsyncClient):
    reg = await client.post("/api/v1/auth/register", json={
        "email": "refresh_test@example.com",
        "password": "RefreshPass1!",
    })
    refresh_token = reg.json()["refresh_token"]

    r = await client.post("/api/v1/auth/refresh", json={"refresh_token": refresh_token})
    assert r.status_code == 200
    data = r.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"


@pytest.mark.asyncio
async def test_refresh_with_access_token_fails(client: AsyncClient):
    reg = await client.post("/api/v1/auth/register", json={
        "email": "wrongtoken@example.com",
        "password": "StrongPass1!",
    })
    access_token = reg.json()["access_token"]

    r = await client.post("/api/v1/auth/refresh", json={"refresh_token": access_token})
    assert r.status_code == 401


# ── Protected routes ───────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_get_me_authenticated(client: AsyncClient):
    reg = await client.post("/api/v1/auth/register", json={
        "email": "me_test@example.com",
        "password": "MeTestPass1!",
    })
    token = reg.json()["access_token"]

    r = await client.get("/api/v1/users/me", headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 200
    data = r.json()
    assert data["email"] == "me_test@example.com"
    assert data["profile"]["display_name"] == "me_test"  # auto-generated from email prefix


@pytest.mark.asyncio
async def test_get_me_unauthenticated(client: AsyncClient):
    r = await client.get("/api/v1/users/me")
    assert r.status_code == 401


@pytest.mark.asyncio
async def test_get_me_invalid_token(client: AsyncClient):
    r = await client.get("/api/v1/users/me", headers={"Authorization": "Bearer garbage.token.here"})
    assert r.status_code == 401


# ── Profile update ─────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_update_profile(client: AsyncClient):
    reg = await client.post("/api/v1/auth/register", json={
        "email": "profile_update@example.com",
        "password": "UpdatePass1!",
    })
    token = reg.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    r = await client.patch("/api/v1/users/me/profile", json={
        "display_name": "Arise Hunter",
        "bio": "Leveling up every day.",
        "theme_preference": "dark",
    }, headers=headers)
    assert r.status_code == 200
    data = r.json()
    assert data["profile"]["display_name"] == "Arise Hunter"
    assert data["profile"]["theme_preference"] == "dark"


@pytest.mark.asyncio
async def test_update_profile_invalid_theme(client: AsyncClient):
    reg = await client.post("/api/v1/auth/register", json={
        "email": "bad_theme@example.com",
        "password": "ThemePass1!",
    })
    token = reg.json()["access_token"]

    r = await client.patch("/api/v1/users/me/profile", json={
        "theme_preference": "rainbow",
    }, headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 422


# ── Logout ─────────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_logout_returns_204(client: AsyncClient):
    r = await client.post("/api/v1/auth/logout")
    assert r.status_code == 204
