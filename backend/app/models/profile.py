import uuid
from datetime import datetime, date
from typing import List, Optional
from sqlalchemy import String, Date, DateTime, func
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base


class Profile(Base):
    """User profile synchronized from Supabase auth.users."""
    __tablename__ = "profiles"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    full_name: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    gender: Mapped[Optional[str]] = mapped_column(String(20), nullable=True)  # pria, wanita, lainnya
    birth_date: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    dominant_skin_type: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)  # Normal, Oily, Dry, Kombinasi, Sensitif
    
    # Fleksibel JSONB untuk daftar concern dan alergi
    skin_concerns: Mapped[list] = mapped_column(JSONB, default=list, server_default="[]")
    allergies: Mapped[list] = mapped_column(JSONB, default=list, server_default="[]")

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )

    # Relasi
    quiz_submissions: Mapped[List["QuizSubmission"]] = relationship(
        "QuizSubmission", back_populates="user", cascade="all, delete-orphan"
    )
    scans: Mapped[List["ScanRecord"]] = relationship(
        "ScanRecord", back_populates="user", cascade="all, delete-orphan"
    )
    journeys: Mapped[List["SkinJourney"]] = relationship(
        "SkinJourney", back_populates="user", cascade="all, delete-orphan"
    )
