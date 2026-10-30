from fastapi import APIRouter
from app.api.routes import health, scan

api_router = APIRouter()

# Register routes
api_router.include_router(health.router, tags=["Health"])
api_router.include_router(scan.router, prefix="/scan", tags=["Skin Scan & ML"])
