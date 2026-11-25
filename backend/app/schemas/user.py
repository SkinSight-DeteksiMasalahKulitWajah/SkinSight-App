import uuid
from datetime import date, datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict, Field


class ProfileOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    email: str
    full_name: Optional[str] = None
    phone: Optional[str] = None
    avatar_url: Optional[str] = None
    gender: Optional[str] = None
    birth_date: Optional[date] = None
    dominant_skin_type: Optional[str] = None
    skin_concerns: List[str] = Field(default_factory=list)
    allergies: List[str] = Field(default_factory=list)
    created_at: datetime
    updated_at: datetime


class ProfileUpdate(BaseModel):
    full_name: Optional[str] = Field(default=None, max_length=255)
    phone: Optional[str] = Field(default=None, max_length=30)
    avatar_url: Optional[str] = Field(default=None, max_length=1024)
    gender: Optional[str] = Field(default=None, max_length=20)
    birth_date: Optional[date] = None
    dominant_skin_type: Optional[str] = Field(default=None, max_length=50)
    skin_concerns: Optional[List[str]] = None
    allergies: Optional[List[str]] = None


class UserSyncRequest(BaseModel):
    full_name: Optional[str] = Field(default=None, max_length=255)
    avatar_url: Optional[str] = Field(default=None, max_length=1024)
