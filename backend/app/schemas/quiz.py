import uuid
from datetime import datetime
from typing import Dict, Optional
from pydantic import BaseModel, ConfigDict, Field


class QuizSubmitRequest(BaseModel):
    answers: Dict[str, object] = Field(default_factory=dict, description="Jawaban kuis: pertanyaan -> jawaban")
    lifestyle_score: Optional[int] = Field(default=None, ge=0, le=100)


class QuizOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    answers: Dict[str, object]
    lifestyle_score: Optional[int] = None
    submitted_at: datetime
