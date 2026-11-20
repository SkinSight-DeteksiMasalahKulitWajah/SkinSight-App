"""Fixture integrasi: memakai database Supabase asli dengan user uji sementara.

Auth Supabase di-override: header `Authorization: Bearer test|<uuid>|<email>` dianggap sah.
Karena profiles.id berelasi ke auth.users, tiap user uji dibuat sementara di auth.users
(email @skinsight-test.invalid; trigger menyiapkan profiles) dan dihapus saat teardown
sehingga seluruh datanya ikut terhapus lewat ON DELETE CASCADE.
"""
import uuid
from typing import Optional

import pytest_asyncio
from fastapi import Header, HTTPException
from httpx import ASGITransport, AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.pool import NullPool

from app.api import deps
from app.core.database import database_connect_args, database_url, get_db
from app.core.security import AuthUser
from app.main import app


def new_user(prefix: str = "user") -> AuthUser:
    uid = uuid.uuid4()
    return AuthUser(id=str(uid), email=f"{prefix}-{uid.hex[:8]}@skinsight-test.invalid", name="Tester")


def _optional_user(authorization: Optional[str] = Header(None)) -> Optional[AuthUser]:
    if not authorization:
        return None
    _, _, token = authorization.partition(" ")
    parts = token.split("|")
    if len(parts) != 3 or parts[0] != "test":
        raise HTTPException(status_code=401, detail="Token uji tidak valid.")
    return AuthUser(id=parts[1], email=parts[2], name="Tester")


def _required_user(authorization: Optional[str] = Header(None)) -> AuthUser:
    user = _optional_user(authorization)
    if user is None:
        raise HTTPException(status_code=401, detail="Autentikasi diperlukan.")
    return user


@pytest_asyncio.fixture
async def make_client(monkeypatch):
    """Factory klien HTTP untuk user tertentu (atau anonim); membersihkan data user saat selesai."""
    engine = create_async_engine(database_url, connect_args=database_connect_args, poolclass=NullPool)
    maker = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    created: list[uuid.UUID] = []
    clients: list[AsyncClient] = []

    async def override_get_db():
        async with maker() as session:
            try:
                yield session
                await session.commit()
            except Exception:
                await session.rollback()
                raise

    app.dependency_overrides[get_db] = override_get_db
    app.dependency_overrides[deps.get_optional_user] = _optional_user
    app.dependency_overrides[deps.get_current_user] = _required_user

    async def build(user: Optional[AuthUser] = None) -> AsyncClient:
        headers = {}
        if user is not None:
            created.append(uuid.UUID(user.id))
            async with maker() as session:
                await session.execute(
                    text(
                        "INSERT INTO auth.users (id, aud, role, email, raw_user_meta_data) "
                        "VALUES (:id, 'authenticated', 'authenticated', :email, CAST(:meta AS jsonb))"
                    ),
                    {"id": uuid.UUID(user.id), "email": user.email, "meta": '{"name": "Tester", "full_name": "Tester"}'},
                )
                await session.commit()
            headers["Authorization"] = f"Bearer test|{user.id}|{user.email}"
        client = AsyncClient(transport=ASGITransport(app=app), base_url="http://test", headers=headers)
        clients.append(client)
        return client

    yield build

    for c in clients:
        await c.aclose()
    app.dependency_overrides.clear()
    async with maker() as session:
        if created:
            await session.execute(text("DELETE FROM auth.users WHERE id = ANY(:ids)"), {"ids": created})
            await session.commit()
    await engine.dispose()
