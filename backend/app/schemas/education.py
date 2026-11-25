import uuid
from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict, Field


class ArticleBase(BaseModel):
    slug: str = Field(..., min_length=1, max_length=150)
    topic: str = Field(..., min_length=1, max_length=50)
    title: str = Field(..., min_length=1, max_length=255)
    summary: str = ""
    body: str = ""
    key_points: List[str] = Field(default_factory=list)
    read_time: Optional[str] = None
    source: Optional[str] = None
    image_url: Optional[str] = None
    is_published: bool = True


class ArticleCreate(ArticleBase):
    pass


class ArticleUpdate(BaseModel):
    slug: Optional[str] = Field(default=None, min_length=1, max_length=150)
    topic: Optional[str] = Field(default=None, min_length=1, max_length=50)
    title: Optional[str] = Field(default=None, min_length=1, max_length=255)
    summary: Optional[str] = None
    body: Optional[str] = None
    key_points: Optional[List[str]] = None
    read_time: Optional[str] = None
    source: Optional[str] = None
    image_url: Optional[str] = None
    is_published: Optional[bool] = None


class ArticleOut(ArticleBase):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    created_at: datetime
