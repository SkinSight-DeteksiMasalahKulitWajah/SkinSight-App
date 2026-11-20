import uuid
from datetime import date, datetime, time, timedelta, timezone
from typing import Optional

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from sqlalchemy import delete, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_profile, get_db, get_optional_profile
from app.core.utils import as_utc
from app.models.profile import Profile
from app.models.scan import ScanRecord
from app.schemas.common import MessageResponse, Page
from app.schemas.scan import (
    ProductRecommendation,
    ScanAnalysisResponse,
    ScanRecordCreate,
    ScanRecordOut,
    ScanRecordUpdate,
)
from app.services.ml_service import ml_service
from app.services.recommendation import find_recommended_products

router = APIRouter()

ALLOWED_MIME_TYPES = {"image/jpeg", "image/png", "image/webp"}
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB


def _record_from_payload(payload: ScanRecordCreate, user_id: uuid.UUID, record_id: str) -> ScanRecord:
    data = payload.model_dump(exclude={"id", "analyzed_at"})
    record = ScanRecord(id=record_id, user_id=user_id, **data)
    if payload.analyzed_at:
        record.analyzed_at = as_utc(payload.analyzed_at)
    return record


@router.post(
    "/analyze",
    response_model=ScanAnalysisResponse,
    summary="Analisis Citra Kulit",
    description=(
        "Menerima upload foto wajah, menjalankan inferensi, dan mengembalikan metrik + rekomendasi produk. "
        "Jika request membawa token Supabase, hasil otomatis disimpan ke riwayat scan."
    ),
)
async def analyze_skin(
    file: UploadFile = File(...),
    budget: Optional[str] = Query(default=None, pattern="^(low|mid|high)$", description="Filter budget produk"),
    save: bool = Query(default=True, description="Simpan ke riwayat bila user login"),
    profile: Optional[Profile] = Depends(get_optional_profile),
    db: AsyncSession = Depends(get_db),
) -> ScanAnalysisResponse:
    if file.content_type not in ALLOWED_MIME_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Format file '{file.content_type}' tidak didukung. Harap upload gambar JPEG, PNG, atau WebP.",
        )

    content = await file.read()
    if len(content) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="Ukuran gambar melebihi batas maksimal 10MB.",
        )

    result = await ml_service.analyze_image(content, filename=file.filename or "upload.jpg")

    # Rekomendasi produk dari katalog database (jika katalog sudah terisi).
    matches = await find_recommended_products(db, result.recommended_ingredients, budget=budget)
    if matches:
        result.recommended_products = [
            ProductRecommendation(
                id=str(p.id),
                name=p.name,
                brand=p.brand,
                category=p.category,
                price=p.price,
                match_reason=reason or "Sesuai dengan kondisi kulitmu.",
                image_url=p.image_url,
            )
            for p, reason in matches
        ]

    if profile is not None and save:
        db.add(
            ScanRecord(
                id=result.id,
                user_id=profile.id,
                analyzed_at=as_utc(result.analyzed_at),
                score=result.score,
                title=result.title,
                skin_type=result.skin_type,
                oil=result.oil,
                pores=result.pores,
                acne=result.acne,
                redness=result.redness,
                visual_findings=result.visual_findings,
                recommended_ingredients=result.recommended_ingredients,
                avoid_ingredients=result.avoid_ingredients,
                detection_counts=result.detection_counts,
                segmentation_areas=result.segmentation_areas,
                class_confidences=result.class_confidences,
                model_version=result.model_version,
                model_connected=result.model_connected,
                is_demo=result.is_demo,
                meta={"skin_type_confidence": result.skin_type_confidence},
            )
        )

    return ScanAnalysisResponse(success=True, message="Analisis citra kulit berhasil diproses.", data=result)


@router.post(
    "/records",
    response_model=ScanRecordOut,
    status_code=status.HTTP_201_CREATED,
    summary="Simpan hasil scan (mis. hasil on-device)",
    description="Idempotent berdasarkan `id`: mengirim ulang id yang sama memperbarui record milik user.",
)
async def create_record(
    payload: ScanRecordCreate,
    profile: Profile = Depends(get_current_profile),
    db: AsyncSession = Depends(get_db),
) -> ScanRecord:
    record_id = payload.id or f"scan-{uuid.uuid4().hex[:12]}"
    existing = await db.get(ScanRecord, record_id)
    if existing is not None:
        if existing.user_id != profile.id:
            raise HTTPException(status_code=409, detail="ID scan sudah dipakai.")
        for field, value in payload.model_dump(exclude={"id", "analyzed_at"}).items():
            setattr(existing, field, value)
        if payload.analyzed_at:
            existing.analyzed_at = as_utc(payload.analyzed_at)
        await db.flush()
        await db.refresh(existing)
        return existing

    record = _record_from_payload(payload, profile.id, record_id)
    db.add(record)
    await db.flush()
    await db.refresh(record)
    return record


@router.get("/history", response_model=Page[ScanRecordOut], summary="Riwayat scan (paginasi)")
async def list_history(
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    on_date: Optional[date] = Query(default=None, alias="date", description="Filter satu hari (UTC), format YYYY-MM-DD"),
    newest_first: bool = True,
    profile: Profile = Depends(get_current_profile),
    db: AsyncSession = Depends(get_db),
) -> Page[ScanRecordOut]:
    conds = [ScanRecord.user_id == profile.id]
    if on_date is not None:
        start = datetime.combine(on_date, time.min, tzinfo=timezone.utc)
        conds += [ScanRecord.analyzed_at >= start, ScanRecord.analyzed_at < start + timedelta(days=1)]

    total = (await db.execute(select(func.count()).select_from(ScanRecord).where(*conds))).scalar_one()
    order = ScanRecord.analyzed_at.desc() if newest_first else ScanRecord.analyzed_at.asc()
    rows = (await db.execute(select(ScanRecord).where(*conds).order_by(order).limit(limit).offset(offset))).scalars().all()
    return Page[ScanRecordOut](
        items=[ScanRecordOut.model_validate(r) for r in rows], total=total, limit=limit, offset=offset
    )


async def _owned_record(db: AsyncSession, scan_id: str, profile: Profile) -> ScanRecord:
    record = await db.get(ScanRecord, scan_id)
    if record is None or record.user_id != profile.id:
        raise HTTPException(status_code=404, detail="Data scan tidak ditemukan.")
    return record


@router.get("/history/{scan_id}", response_model=ScanRecordOut, summary="Detail satu hasil scan")
async def get_history_item(
    scan_id: str,
    profile: Profile = Depends(get_current_profile),
    db: AsyncSession = Depends(get_db),
) -> ScanRecord:
    return await _owned_record(db, scan_id, profile)


@router.patch("/history/{scan_id}", response_model=ScanRecordOut, summary="Update judul / foto / meta scan")
async def update_history_item(
    scan_id: str,
    payload: ScanRecordUpdate,
    profile: Profile = Depends(get_current_profile),
    db: AsyncSession = Depends(get_db),
) -> ScanRecord:
    record = await _owned_record(db, scan_id, profile)
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(record, field, value)
    await db.flush()
    await db.refresh(record)
    return record


@router.delete("/history/{scan_id}", response_model=MessageResponse, summary="Hapus satu hasil scan")
async def delete_history_item(
    scan_id: str,
    profile: Profile = Depends(get_current_profile),
    db: AsyncSession = Depends(get_db),
) -> MessageResponse:
    record = await _owned_record(db, scan_id, profile)
    await db.delete(record)
    return MessageResponse(message="Data scan dihapus.")


@router.delete("/history", response_model=MessageResponse, summary="Hapus seluruh riwayat scan")
async def clear_history(
    profile: Profile = Depends(get_current_profile),
    db: AsyncSession = Depends(get_db),
) -> MessageResponse:
    await db.execute(delete(ScanRecord).where(ScanRecord.user_id == profile.id))
    return MessageResponse(message="Seluruh riwayat scan dihapus.")
