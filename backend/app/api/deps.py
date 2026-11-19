import uuid
from typing import Optional

from fastapi import Depends, Header, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.database import get_db
from app.core.security import AuthError, AuthUser, verify_token
from app.models.profile import Profile

__all__ = [
    "get_db",
    "get_current_user_token",
    "get_current_user",
    "get_optional_user",
    "get_current_profile",
    "get_optional_profile",
    "require_admin",
]


def _unauthorized(detail: str) -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail=detail,
        headers={"WWW-Authenticate": "Bearer"},
    )


async def get_current_user_token(authorization: Optional[str] = Header(None)) -> Optional[str]:
    """Extract Bearer token from request authorization header."""
    if not authorization:
        return None

    scheme, _, token = authorization.partition(" ")
    if scheme.lower() != "bearer" or not token:
        raise _unauthorized("Header otorisasi tidak valid.")
    return token


async def get_optional_user(token: Optional[str] = Depends(get_current_user_token)) -> Optional[AuthUser]:
    if token is None:
        return None
    try:
        return await verify_token(token)
    except AuthError as exc:
        raise _unauthorized(str(exc))


async def get_current_user(user: Optional[AuthUser] = Depends(get_optional_user)) -> AuthUser:
    if user is None:
        raise _unauthorized("Autentikasi diperlukan.")
    return user


async def get_current_profile(
    user: AuthUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Profile:
    """Profil milik user yang sedang login; dibuat otomatis jika belum ada."""
    uid = uuid.UUID(user.id)
    profile = await db.get(Profile, uid)
    if profile is not None:
        return profile

    if not user.email:
        raise HTTPException(status_code=400, detail="Akun tidak memiliki email.")
    existing = (await db.execute(select(Profile).where(Profile.email == user.email))).scalar_one_or_none()
    if existing is not None:
        # Profil dibuat manual sebelum sinkron: adopsi id dari Supabase Auth.
        existing.id = uid
        profile = existing
    else:
        profile = Profile(id=uid, email=user.email, full_name=user.name)
        db.add(profile)
    await db.flush()
    return profile


async def require_admin(user: AuthUser = Depends(get_current_user)) -> AuthUser:
    admins = {e.strip().lower() for e in settings.ADMIN_EMAILS.split(",") if e.strip()}
    if not user.email or user.email.lower() not in admins:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Hanya admin yang diizinkan.")
    return user


async def get_optional_profile(
    user: Optional[AuthUser] = Depends(get_optional_user),
    db: AsyncSession = Depends(get_db),
) -> Optional[Profile]:
    """Profil jika request membawa token valid; None untuk akses anonim."""
    if user is None:
        return None
    return await get_current_profile(user=user, db=db)
