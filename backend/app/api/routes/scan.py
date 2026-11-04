from fastapi import APIRouter, File, UploadFile, HTTPException, status
from app.schemas.scan import ScanAnalysisResponse
from app.services.ml_service import ml_service

router = APIRouter()

ALLOWED_MIME_TYPES = {"image/jpeg", "image/png", "image/webp"}
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB


@router.post(
    "/analyze",
    response_model=ScanAnalysisResponse,
    summary="Analisis Citra Kulit",
    description="Menerima upload foto wajah pengguna, menjalankan inferensi kondisi kulit, dan memberikan rekomendasi."
)
async def analyze_skin(file: UploadFile = File(...)) -> ScanAnalysisResponse:
    if file.content_type not in ALLOWED_MIME_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Format file '{file.content_type}' tidak didukung. Harap upload gambar JPEG, PNG, atau WebP."
        )

    content = await file.read()
    if len(content) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="Ukuran gambar melebihi batas maksimal 10MB."
        )

    result = await ml_service.analyze_image(content, filename=file.filename or "upload.jpg")

    return ScanAnalysisResponse(
        success=True,
        message="Analisis citra kulit berhasil diproses.",
        data=result
    )
