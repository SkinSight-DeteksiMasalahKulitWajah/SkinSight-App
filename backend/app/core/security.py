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


@lru_cache(maxsize=1)
def _jwks_client() -> PyJWKClient:
    return PyJWKClient(f"{settings.SUPABASE_URL.rstrip('/')}/auth/v1/.well-known/jwks.json")


def _user_from_claims(claims: dict) -> AuthUser:
    sub = claims.get("sub")
    if not sub:
        raise AuthError("Token tidak memiliki subject.")
    meta = claims.get("user_metadata") or {}
    return AuthUser(
        id=sub,
        email=claims.get("email"),
        name=meta.get("name") or meta.get("full_name"),
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
    return AuthUser(id=data["id"], email=data.get("email"), name=meta.get("name") or meta.get("full_name"))


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
