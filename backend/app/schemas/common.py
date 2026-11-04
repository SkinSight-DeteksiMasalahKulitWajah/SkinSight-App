from datetime import datetime
from typing import Generic, Optional, TypeVar
from pydantic import BaseModel, Field

T = TypeVar("T")


class HealthCheckResponse(BaseModel):
    status: str = Field(default="ok", example="ok")
    app_name: str = Field(..., example="SkinSight API")
    version: str = Field(..., example="1.0.0")
    environment: str = Field(..., example="development")
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class MessageResponse(BaseModel):
    message: str


class ApiResponse(BaseModel, Generic[T]):
    success: bool = True
    message: Optional[str] = None
    data: Optional[T] = None
