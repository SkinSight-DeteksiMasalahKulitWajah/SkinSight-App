import uuid
from datetime import date, datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, ConfigDict, Field

JOURNEY_STATUSES = ("active", "completed", "cancelled", "paused")


class JourneyCreate(BaseModel):
    id: Optional[uuid.UUID] = Field(default=None, description="ID dari klien (opsional, untuk sinkron offline)")
    title: str = Field(..., min_length=1, max_length=255)
    target_concern: str = Field(default="Umum", min_length=1, max_length=100)
    status: str = "active"
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    is_pinned: bool = False
    meta: Dict[str, Any] = Field(default_factory=dict)


class JourneyUpdate(BaseModel):
    title: Optional[str] = Field(default=None, min_length=1, max_length=255)
    target_concern: Optional[str] = Field(default=None, min_length=1, max_length=100)
    status: Optional[str] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    is_pinned: Optional[bool] = None
    meta: Optional[Dict[str, Any]] = None


class CheckinCreate(BaseModel):
    id: Optional[uuid.UUID] = None
    journey_id: uuid.UUID
    checkin_date: Optional[date] = None
    photo_url: Optional[str] = Field(default=None, max_length=1024)
    notes: Optional[str] = None
    condition_rating: Optional[int] = Field(default=None, ge=1, le=5)
    meta: Dict[str, Any] = Field(default_factory=dict)


class CheckinUpdate(BaseModel):
    checkin_date: Optional[date] = None
    photo_url: Optional[str] = Field(default=None, max_length=1024)
    notes: Optional[str] = None
    condition_rating: Optional[int] = Field(default=None, ge=1, le=5)
    meta: Optional[Dict[str, Any]] = None


class CheckinOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    journey_id: uuid.UUID
    checkin_date: date
    photo_url: Optional[str] = None
    notes: Optional[str] = None
    condition_rating: Optional[int] = None
    meta: Dict[str, Any] = Field(default_factory=dict)
    created_at: datetime


class JourneyOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    title: str
    target_concern: str
    status: str
    start_date: date
    end_date: Optional[date] = None
    is_pinned: bool = False
    deleted_at: Optional[datetime] = None
    meta: Dict[str, Any] = Field(default_factory=dict)
    created_at: datetime
    checkins_count: int = 0


class JourneyDetail(JourneyOut):
    checkins: List[CheckinOut] = Field(default_factory=list)
