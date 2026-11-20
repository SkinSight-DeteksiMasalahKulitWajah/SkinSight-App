from fastapi import APIRouter
from app.api.routes import (
    catalog,
    education,
    health,
    journeys,
    quiz,
    recommendation,
    scan,
    users,
)

api_router = APIRouter()

# Register routes
api_router.include_router(health.router, tags=["Health"])
api_router.include_router(scan.router, prefix="/scan", tags=["Skin Scan & ML"])
api_router.include_router(recommendation.router, prefix="/recommendation", tags=["LLM Recommendation"])
api_router.include_router(users.router, prefix="/users", tags=["Users & Profile"])
api_router.include_router(quiz.router, prefix="/quiz", tags=["Quiz"])
api_router.include_router(journeys.router, prefix="/journeys", tags=["Skin Journeys"])
api_router.include_router(catalog.router, prefix="/catalog", tags=["Catalog"])
api_router.include_router(education.router, prefix="/education", tags=["Education"])
