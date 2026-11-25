from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db
from app.core.config import settings
from app.schemas.common import HealthCheckResponse

router = APIRouter()


@router.get("/health", response_model=HealthCheckResponse, summary="Health Check")
async def health_check(db: AsyncSession = Depends(get_db)) -> HealthCheckResponse:
    """Status backend + konektivitas database (tidak gagal bila database mati)."""
    try:
        await db.execute(text("SELECT 1"))
        database = "ok"
    except Exception:
        database = "unavailable"
    return HealthCheckResponse(
        status="ok",
        app_name=settings.PROJECT_NAME,
        version=settings.VERSION,
        environment=settings.ENVIRONMENT,
        database=database,
    )
