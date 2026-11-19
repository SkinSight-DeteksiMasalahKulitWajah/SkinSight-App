from fastapi import APIRouter, HTTPException, status
from app.schemas.recommendation import (
    RecommendationRequest,
    RecommendationResponse,
)
from app.services.llm_service import llm_service

router = APIRouter()


@router.post(
    "/generate",
    response_model=RecommendationResponse,
    summary="Generate Rekomendasi Perawatan Kulit (LLM)",
    description=(
        "Menerima data hasil scan wajah, jawaban kuesioner, dan riwayat check-in, "
        "lalu menghasilkan rekomendasi perawatan kulit personal menggunakan "
        "Google Gemini API. Fallback ke rekomendasi statis jika LLM tidak tersedia."
    ),
)
async def generate_recommendation(
    payload: RecommendationRequest,
) -> RecommendationResponse:
    try:
        result = await llm_service.generate_recommendation(payload)
        return RecommendationResponse(
            success=True,
            message="Rekomendasi perawatan berhasil dibuat.",
            data=result,
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal menghasilkan rekomendasi: {str(e)}",
        )
