import uuid
from datetime import datetime, date
from typing import List, Optional
from sqlalchemy import String, Integer, Text, Date, DateTime, ForeignKey, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base


class SkinJourney(Base):
    """User tracking journey for skincare progress."""
    __tablename__ = "skin_journeys"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("profiles.id", ondelete="CASCADE"), index=True, nullable=False
    )
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    target_concern: Mapped[str] = mapped_column(String(100), nullable=False)  # Jerawat, Pori-pori, Kusam, dll.
    status: Mapped[str] = mapped_column(String(30), default="active", nullable=False)  # active, completed, paused
    start_date: Mapped[date] = mapped_column(Date, default=date.today, nullable=False)
    end_date: Mapped[Optional[date]] = mapped_column(Date, nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    # Relasi
    user: Mapped["Profile"] = relationship("Profile", back_populates="journeys")
    checkins: Mapped[List["JourneyCheckin"]] = relationship(
        "JourneyCheckin", back_populates="journey", cascade="all, delete-orphan"
    )


class JourneyCheckin(Base):
    """Periodic user check-in entries with progress photos."""
    __tablename__ = "journey_checkins"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    journey_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("skin_journeys.id", ondelete="CASCADE"), index=True, nullable=False
    )
    checkin_date: Mapped[date] = mapped_column(Date, default=date.today, nullable=False)
    photo_url: Mapped[Optional[str]] = mapped_column(String(1024), nullable=True)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    condition_rating: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)  # Skala 1 - 5

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    # Relasi
    journey: Mapped["SkinJourney"] = relationship("SkinJourney", back_populates="checkins")
