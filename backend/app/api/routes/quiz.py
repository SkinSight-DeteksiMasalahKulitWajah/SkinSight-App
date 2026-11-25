import uuid
from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_profile, get_db
from app.models.profile import Profile
from app.models.quiz import QuizSubmission
from app.schemas.common import MessageResponse
from app.schemas.quiz import QuizOut, QuizSubmitRequest

router = APIRouter()


@router.post("/submit", response_model=QuizOut, status_code=status.HTTP_201_CREATED, summary="Simpan hasil kuis")
async def submit_quiz(
    payload: QuizSubmitRequest,
    profile: Profile = Depends(get_current_profile),
    db: AsyncSession = Depends(get_db),
) -> QuizSubmission:
    quiz = QuizSubmission(user_id=profile.id, answers=payload.answers, lifestyle_score=payload.lifestyle_score)
    db.add(quiz)
    await db.flush()
    await db.refresh(quiz)
    return quiz


@router.get("", response_model=List[QuizOut], summary="Riwayat kuis (terbaru dulu)")
async def list_quiz(
    profile: Profile = Depends(get_current_profile),
    db: AsyncSession = Depends(get_db),
) -> List[QuizSubmission]:
    stmt = select(QuizSubmission).where(QuizSubmission.user_id == profile.id).order_by(QuizSubmission.submitted_at.desc())
    return list((await db.execute(stmt)).scalars().all())


@router.get("/latest", response_model=QuizOut, summary="Kuis terbaru")
async def latest_quiz(
    profile: Profile = Depends(get_current_profile),
    db: AsyncSession = Depends(get_db),
) -> QuizSubmission:
    stmt = (
        select(QuizSubmission)
        .where(QuizSubmission.user_id == profile.id)
        .order_by(QuizSubmission.submitted_at.desc())
        .limit(1)
    )
    quiz = (await db.execute(stmt)).scalar_one_or_none()
    if quiz is None:
        raise HTTPException(status_code=404, detail="Belum ada kuis yang disimpan.")
    return quiz


@router.delete("/{quiz_id}", response_model=MessageResponse, summary="Hapus satu kuis")
async def delete_quiz(
    quiz_id: uuid.UUID,
    profile: Profile = Depends(get_current_profile),
    db: AsyncSession = Depends(get_db),
) -> MessageResponse:
    quiz = await db.get(QuizSubmission, quiz_id)
    if quiz is None or quiz.user_id != profile.id:
        raise HTTPException(status_code=404, detail="Kuis tidak ditemukan.")
    await db.delete(quiz)
    return MessageResponse(message="Kuis dihapus.")
