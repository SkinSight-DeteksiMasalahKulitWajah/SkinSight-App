import uuid
from datetime import date, datetime, timezone
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_profile, get_db
from app.models.journey import JourneyCheckin, SkinJourney
from app.models.profile import Profile
from app.schemas.common import MessageResponse
from app.schemas.journey import (
    JOURNEY_STATUSES,
    CheckinCreate,
    CheckinOut,
    CheckinUpdate,
    JourneyCreate,
    JourneyDetail,
    JourneyOut,
    JourneyUpdate,
)

router = APIRouter()


def _check_status(value: Optional[str]) -> None:
    if value is not None and value not in JOURNEY_STATUSES:
        raise HTTPException(status_code=422, detail=f"Status harus salah satu dari: {', '.join(JOURNEY_STATUSES)}.")


async def _owned_journey(db: AsyncSession, journey_id: uuid.UUID, profile: Profile) -> SkinJourney:
    journey = await db.get(SkinJourney, journey_id)
    if journey is None or journey.user_id != profile.id:
        raise HTTPException(status_code=404, detail="Journey tidak ditemukan.")
    return journey


async def _checkin_counts(db: AsyncSession, journey_ids: List[uuid.UUID]) -> dict:
    if not journey_ids:
        return {}
    rows = await db.execute(
        select(JourneyCheckin.journey_id, func.count())
        .where(JourneyCheckin.journey_id.in_(journey_ids))
        .group_by(JourneyCheckin.journey_id)
    )
    return {jid: n for jid, n in rows.all()}


def _to_out(journey: SkinJourney, count: int) -> JourneyOut:
    out = JourneyOut.model_validate(journey)
    out.checkins_count = count
    return out


@router.get("", response_model=List[JourneyOut], summary="Daftar journey milik user")
async def list_journeys(
    status_filter: Optional[str] = Query(default=None, alias="status", description="active|completed|cancelled|paused"),
    include_deleted: bool = Query(default=False, description="Sertakan journey di sampah (soft-delete)"),
    profile: Profile = Depends(get_current_profile),
    db: AsyncSession = Depends(get_db),
) -> List[JourneyOut]:
    _check_status(status_filter)
    stmt = select(SkinJourney).where(SkinJourney.user_id == profile.id)
    if status_filter:
        stmt = stmt.where(SkinJourney.status == status_filter)
    if not include_deleted:
        stmt = stmt.where(SkinJourney.deleted_at.is_(None))
    stmt = stmt.order_by(SkinJourney.is_pinned.desc(), SkinJourney.created_at.desc())
    journeys = list((await db.execute(stmt)).scalars().all())
    counts = await _checkin_counts(db, [j.id for j in journeys])
    return [_to_out(j, counts.get(j.id, 0)) for j in journeys]


@router.post("", response_model=JourneyOut, status_code=status.HTTP_201_CREATED, summary="Buat journey baru")
async def create_journey(
    payload: JourneyCreate,
    profile: Profile = Depends(get_current_profile),
    db: AsyncSession = Depends(get_db),
) -> JourneyOut:
    _check_status(payload.status)
    if payload.id is not None:
        existing = await db.get(SkinJourney, payload.id)
        if existing is not None:
            raise HTTPException(status_code=409, detail="Journey dengan ID ini sudah ada. Gunakan PUT untuk memperbarui.")
    journey = SkinJourney(
        id=payload.id or uuid.uuid4(),
        user_id=profile.id,
        title=payload.title.strip(),
        target_concern=payload.target_concern,
        status=payload.status,
        start_date=payload.start_date or date.today(),
        end_date=payload.end_date,
        is_pinned=payload.is_pinned,
        meta=payload.meta,
    )
    db.add(journey)
    await db.flush()
    await db.refresh(journey)
    return _to_out(journey, 0)


@router.post("/checkin", response_model=CheckinOut, status_code=status.HTTP_201_CREATED, summary="Simpan check-in progres")
async def create_checkin(
    payload: CheckinCreate,
    profile: Profile = Depends(get_current_profile),
    db: AsyncSession = Depends(get_db),
) -> JourneyCheckin:
    await _owned_journey(db, payload.journey_id, profile)
    if payload.id is not None and await db.get(JourneyCheckin, payload.id) is not None:
        raise HTTPException(status_code=409, detail="Check-in dengan ID ini sudah ada.")
    checkin = JourneyCheckin(
        id=payload.id or uuid.uuid4(),
        journey_id=payload.journey_id,
        checkin_date=payload.checkin_date or date.today(),
        photo_url=payload.photo_url,
        notes=payload.notes,
        condition_rating=payload.condition_rating,
        meta=payload.meta,
    )
    db.add(checkin)
    await db.flush()
    await db.refresh(checkin)
    return checkin


async def _owned_checkin(db: AsyncSession, checkin_id: uuid.UUID, profile: Profile) -> JourneyCheckin:
    checkin = await db.get(JourneyCheckin, checkin_id)
    if checkin is None:
        raise HTTPException(status_code=404, detail="Check-in tidak ditemukan.")
    journey = await db.get(SkinJourney, checkin.journey_id)
    if journey is None or journey.user_id != profile.id:
        raise HTTPException(status_code=404, detail="Check-in tidak ditemukan.")
    return checkin


@router.put("/checkin/{checkin_id}", response_model=CheckinOut, summary="Update check-in")
async def update_checkin(
    checkin_id: uuid.UUID,
    payload: CheckinUpdate,
    profile: Profile = Depends(get_current_profile),
    db: AsyncSession = Depends(get_db),
) -> JourneyCheckin:
    checkin = await _owned_checkin(db, checkin_id, profile)
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(checkin, field, value)
    await db.flush()
    await db.refresh(checkin)
    return checkin


@router.delete("/checkin/{checkin_id}", response_model=MessageResponse, summary="Hapus check-in")
async def delete_checkin(
    checkin_id: uuid.UUID,
    profile: Profile = Depends(get_current_profile),
    db: AsyncSession = Depends(get_db),
) -> MessageResponse:
    checkin = await _owned_checkin(db, checkin_id, profile)
    await db.delete(checkin)
    return MessageResponse(message="Check-in dihapus.")


@router.get("/{journey_id}", response_model=JourneyDetail, summary="Detail journey beserta check-in")
async def get_journey(
    journey_id: uuid.UUID,
    profile: Profile = Depends(get_current_profile),
    db: AsyncSession = Depends(get_db),
) -> JourneyDetail:
    journey = await _owned_journey(db, journey_id, profile)
    checkins = list(
        (
            await db.execute(
                select(JourneyCheckin)
                .where(JourneyCheckin.journey_id == journey.id)
                .order_by(JourneyCheckin.checkin_date.asc(), JourneyCheckin.created_at.asc())
            )
        )
        .scalars()
        .all()
    )
    base = _to_out(journey, len(checkins))  # tidak menyentuh relasi lazy `checkins`
    return JourneyDetail(**base.model_dump(), checkins=[CheckinOut.model_validate(c) for c in checkins])


@router.put("/{journey_id}", response_model=JourneyOut, summary="Update journey (nama, status, pin, meta)")
async def update_journey(
    journey_id: uuid.UUID,
    payload: JourneyUpdate,
    profile: Profile = Depends(get_current_profile),
    db: AsyncSession = Depends(get_db),
) -> JourneyOut:
    _check_status(payload.status)
    journey = await _owned_journey(db, journey_id, profile)
    data = payload.model_dump(exclude_unset=True)
    if "title" in data and data["title"]:
        data["title"] = data["title"].strip()
    for field, value in data.items():
        setattr(journey, field, value)
    await db.flush()
    await db.refresh(journey)
    counts = await _checkin_counts(db, [journey.id])
    return _to_out(journey, counts.get(journey.id, 0))


@router.delete("/{journey_id}", response_model=MessageResponse, summary="Hapus journey (sampah atau permanen)")
async def delete_journey(
    journey_id: uuid.UUID,
    permanent: bool = Query(default=False, description="true = hapus permanen beserta check-in"),
    profile: Profile = Depends(get_current_profile),
    db: AsyncSession = Depends(get_db),
) -> MessageResponse:
    journey = await _owned_journey(db, journey_id, profile)
    if permanent:
        await db.delete(journey)
        return MessageResponse(message="Journey dihapus permanen.")
    journey.deleted_at = datetime.now(timezone.utc)
    journey.is_pinned = False
    return MessageResponse(message="Journey dipindahkan ke sampah.")


@router.post("/{journey_id}/restore", response_model=JourneyOut, summary="Pulihkan journey dari sampah")
async def restore_journey(
    journey_id: uuid.UUID,
    profile: Profile = Depends(get_current_profile),
    db: AsyncSession = Depends(get_db),
) -> JourneyOut:
    journey = await _owned_journey(db, journey_id, profile)
    journey.deleted_at = None
    await db.flush()
    await db.refresh(journey)
    counts = await _checkin_counts(db, [journey.id])
    return _to_out(journey, counts.get(journey.id, 0))
