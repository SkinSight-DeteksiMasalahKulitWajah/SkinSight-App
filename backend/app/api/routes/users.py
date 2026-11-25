from typing import Optional

from fastapi import APIRouter, Body, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_profile, get_db, is_placeholder_name
from app.models.profile import Profile
from app.schemas.common import MessageResponse
from app.schemas.user import ProfileOut, ProfileUpdate, UserSyncRequest

router = APIRouter()


@router.post("/sync", response_model=ProfileOut, summary="Sinkron user Supabase Auth ke tabel profiles")
async def sync_user(
    body: Optional[UserSyncRequest] = Body(default=None),
    profile: Profile = Depends(get_current_profile),
    db: AsyncSession = Depends(get_db),
) -> Profile:
    """Idempotent: membuat profil bila belum ada, mengisi nama/avatar asli bila masih kosong atau placeholder."""
    changed = False
    if body and body.full_name and body.full_name.strip():
        candidate = body.full_name.strip()
        if is_placeholder_name(profile.full_name) and not is_placeholder_name(candidate):
            profile.full_name = candidate
            changed = True
    if body and body.avatar_url and body.avatar_url.strip() and not profile.avatar_url:
        profile.avatar_url = body.avatar_url.strip()
        changed = True
    if changed:
        await db.flush()
    await db.refresh(profile)
    return profile


@router.get("/me", response_model=ProfileOut, summary="Ambil profil sendiri")
async def get_me(profile: Profile = Depends(get_current_profile)) -> Profile:
    return profile


@router.put("/me", response_model=ProfileOut, summary="Update profil & preferensi kulit")
async def update_me(
    payload: ProfileUpdate,
    profile: Profile = Depends(get_current_profile),
    db: AsyncSession = Depends(get_db),
) -> Profile:
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(profile, field, value)
    await db.flush()
    await db.refresh(profile)
    return profile


@router.delete("/me", response_model=MessageResponse, summary="Hapus data profil beserta seluruh riwayat")
async def delete_me(
    profile: Profile = Depends(get_current_profile),
    db: AsyncSession = Depends(get_db),
) -> MessageResponse:
    await db.delete(profile)
    return MessageResponse(message="Data profil dan riwayat berhasil dihapus.")
