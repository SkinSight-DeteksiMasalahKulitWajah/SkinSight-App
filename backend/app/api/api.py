from fastapi import APIRouter
from app.api.routes import health, scan, recommendation

api_router = APIRouter()

# Register routes
api_router.include_router(health.router, tags=["Health"])
api_router.include_router(scan.router, prefix="/scan", tags=["Skin Scan & ML"])
api_router.include_router(recommendation.router, prefix="/recommendation", tags=["LLM Recommendation"])
