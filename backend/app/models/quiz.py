import uuid
from datetime import datetime
from typing import Optional
from sqlalchemy import Integer, DateTime, ForeignKey, func
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base


class QuizSubmission(Base):
    """User lifestyle and initial skin questionnaire submissions."""
    __tablename__ = "quiz_submissions"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("profiles.id", ondelete="CASCADE"), index=True, nullable=False
    )
    
    # Simpan jawaban kuis (tidur, konsumsi air, paparan matahari, rutinitas)
    answers: Mapped[dict] = mapped_column(JSONB, default=dict, server_default="{}")
    lifestyle_score: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)

    submitted_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    # Relasi
    user: Mapped["Profile"] = relationship("Profile", back_populates="quiz_submissions")
