from datetime import datetime
from typing import Optional
from sqlalchemy import String, Integer, Boolean, DateTime, ForeignKey, func
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base


class ScanRecord(Base):
    """Historical records of skin facial image scans and ML detections."""
    __tablename__ = "scan_records"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)  # contoh: scan-abc123xyz
    user_id: Mapped[Optional[str]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("profiles.id", ondelete="SET NULL"), index=True, nullable=True
    )
    
    image_url: Mapped[Optional[str]] = mapped_column(String(1024), nullable=True)
    score: Mapped[int] = mapped_column(Integer, default=0, nullable=False)  # 0 - 100
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    skin_type: Mapped[str] = mapped_column(String(50), nullable=False)
    
    # 4 Skor Masalah Kulit Utama
    oil: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    pores: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    acne: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    redness: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    # Temuan visual (misal ["Pori-pori tampak membesar", "Minyak zona T"])
    visual_findings: Mapped[list] = mapped_column(JSONB, default=list, server_default="[]")
    
    # Bahan aktif yang direkomendasikan & dihindari
    recommended_ingredients: Mapped[list] = mapped_column(JSONB, default=list, server_default="[]")
    avoid_ingredients: Mapped[list] = mapped_column(JSONB, default=list, server_default="[]")

    # Output detail inferensi (bounding box, segmentation area, confidence)
    detection_counts: Mapped[dict] = mapped_column(JSONB, default=dict, server_default="{}")
    segmentation_areas: Mapped[dict] = mapped_column(JSONB, default=dict, server_default="{}")
    class_confidences: Mapped[dict] = mapped_column(JSONB, default=dict, server_default="{}")

    # Metadata model & status demo
    model_version: Mapped[Optional[str]] = mapped_column(String(50), default="v1.0.0")
    model_connected: Mapped[bool] = mapped_column(Boolean, default=True)
    is_demo: Mapped[bool] = mapped_column(Boolean, default=False)

    analyzed_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    # Relasi
    user: Mapped[Optional["Profile"]] = relationship("Profile", back_populates="scans")
