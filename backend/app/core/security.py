"""Verifikasi access token (JWT) Supabase Auth.

Urutan strategi:
1. Token bertanda tangan asimetris (ES256/RS256, default project baru) -> JWKS Supabase.
2. Token HS256 + SUPABASE_JWT_SECRET terisi -> verifikasi lokal.
3. Token HS256 tanpa secret -> validasi ke endpoint /auth/v1/user Supabase.
"""
from dataclasses import dataclass
from functools import lru_cache
from typing import Optional

import httpx
import jwt
from jwt import PyJWKClient

from app.core.config import settings


class AuthError(Exception):
    pass


@dataclass
class AuthUser:
    id: str
    email: Optional[str]
    name: Optional[str]
    avatar_url: Optional[str] = None


def extract_display_name(meta: dict, email: Optional[str] = None) -> Optional[str]:
    """Ambil nama tampilan asli dari metadata OAuth Google / Supabase Auth."""
    if isinstance(meta, dict):
        for key in ("full_name", "name", "preferred_username", "user_name"):
            val = meta.get(key)
            if isinstance(val, str) and val.strip():
                return val.strip()
        given = (meta.get("given_name") or "").strip() if isinstance(meta.get("given_name"), str) else ""
        family = (meta.get("family_name") or "").strip() if isinstance(meta.get("family_name"), str) else ""
        combined = f"{given} {family}".strip()
        if combined:
            return combined
    if email and "@" in email:
        local = email.split("@", 1)[0].strip()
        if local:
            return local
    return None


def extract_avatar_url(meta: dict) -> Optional[str]:
    if isinstance(meta, dict):
        for key in ("avatar_url", "picture"):
            val = meta.get(key)
            if isinstance(val, str) and val.strip():
                return val.strip()
    return None


@lru_cache(maxsize=1)
def _jwks_client() -> PyJWKClient:
    return PyJWKClient(f"{settings.SUPABASE_URL.rstrip('/')}/auth/v1/.well-known/jwks.json")


def _user_from_claims(claims: dict) -> AuthUser:
    sub = claims.get("sub")
    if not sub:
        raise AuthError("Token tidak memiliki subject.")
    meta = claims.get("user_metadata") or {}
    email = claims.get("email")
    return AuthUser(
        id=sub,
        email=email,
        name=extract_display_name(meta, email),
        avatar_url=extract_avatar_url(meta),
    )


async def _verify_remote(token: str) -> AuthUser:
    if not settings.SUPABASE_ANON_KEY:
        raise AuthError("SUPABASE_JWT_SECRET atau SUPABASE_ANON_KEY belum dikonfigurasi di server.")
    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.get(
            f"{settings.SUPABASE_URL.rstrip('/')}/auth/v1/user",
            headers={"Authorization": f"Bearer {token}", "apikey": settings.SUPABASE_ANON_KEY},
        )
    if resp.status_code != 200:
        raise AuthError("Token tidak valid atau kedaluwarsa.")
    data = resp.json()
    meta = data.get("user_metadata") or {}
    email = data.get("email")
    return AuthUser(
        id=data["id"],
        email=email,
        name=extract_display_name(meta, email),
        avatar_url=extract_avatar_url(meta),
    )


async def verify_token(token: str) -> AuthUser:
    try:
        header = jwt.get_unverified_header(token)
    except jwt.PyJWTError as exc:
        raise AuthError("Format token tidak valid.") from exc

    alg = header.get("alg", "")
    try:
        if alg == "HS256":
            if not settings.SUPABASE_JWT_SECRET:
                return await _verify_remote(token)
            claims = jwt.decode(
                token,
                settings.SUPABASE_JWT_SECRET,
                algorithms=["HS256"],
                audience="authenticated",
            )
        else:
            signing_key = _jwks_client().get_signing_key_from_jwt(token)
            claims = jwt.decode(
                token,
                signing_key.key,
                algorithms=[alg],
                audience="authenticated",
            )
    except jwt.ExpiredSignatureError as exc:
        raise AuthError("Token kedaluwarsa.") from exc
    except (jwt.PyJWTError, jwt.PyJWKClientError) as exc:
        raise AuthError("Token tidak valid.") from exc
    return _user_from_claims(claims)
