from datetime import datetime
from typing import Dict, List, Optional
from pydantic import BaseModel, Field


# ───────────────────────────── Request ─────────────────────────────

class ScanData(BaseModel):
    """Data hasil scan wajah dari mobile (on-device inference)."""
    skin_type: str = Field(..., description="Normal | Oily | Dry | Combination")
    skin_type_confidence: Optional[float] = Field(None, ge=0, le=1)
    visual_findings: List[str] = Field(default_factory=list)
    detection_counts: Dict[str, int] = Field(default_factory=dict)
    segmentation_areas: Dict[str, float] = Field(default_factory=dict)
    class_confidences: Dict[str, float] = Field(default_factory=dict)


class QuizAnswers(BaseModel):
    """Jawaban kuesioner pra-scan M01–M07."""
    M01: Optional[str] = Field(None, description="Sedang pakai bahan aktif?")
    M02: Optional[str] = Field(None, description="Rutin perawatan 7 hari?")
    M03: Optional[str] = Field(None, description="Keluhan saat ini?")
    M04: Optional[str] = Field(None, description="Riwayat reaksi buruk?")
    M05: Optional[str] = Field(None, description="Frekuensi sunscreen?")
    M06: Optional[str] = Field(None, description="Dalam perawatan dokter?")
    M07: Optional[str] = Field(None, description="Fokus masalah (pipe-separated)")
    regimen_name: Optional[str] = None
    regimen_class: Optional[str] = None
    regimen_start: Optional[str] = None


class CheckinHistory(BaseModel):
    """Ringkasan check-in mingguan terbaru."""
    week: int = 0
    per_class: Dict[str, str] = Field(default_factory=dict, description="Perubahan per kelas: Membaik/Sama/Memburuk")
    treatment: Optional[str] = None
    irritation: Optional[str] = None


class RecommendationRequest(BaseModel):
    """Payload yang dikirim mobile untuk mendapatkan rekomendasi LLM."""
    scan: ScanData
    quiz: QuizAnswers = Field(default_factory=QuizAnswers)
    checkin_history: List[CheckinHistory] = Field(default_factory=list)
    language: str = Field(default="id", description="Bahasa output: id | en")


# ───────────────────────────── Response ─────────────────────────────

class FindingEducation(BaseModel):
    """Edukasi untuk satu temuan visual."""
    finding: str = Field(..., description="Nama kelas temuan, e.g. 'Acne'")
    finding_label: str = Field(..., description="Label lokal, e.g. 'Jerawat'")
    explanation: str = Field(..., description="Penjelasan kontekstual temuan")
    care_tips: List[str] = Field(default_factory=list, description="Langkah perawatan spesifik")
    timeline: str = Field("", description="Estimasi waktu evaluasi")


class RoutineStep(BaseModel):
    """Satu langkah dalam rutinitas perawatan."""
    order: int
    step_name: str = Field(..., description="e.g. 'Cleanser', 'Toner', 'Serum'")
    description: str
    ingredient_highlights: List[str] = Field(default_factory=list)
    when: str = Field("pagi & malam", description="pagi | malam | pagi & malam")


class RecommendationResult(BaseModel):
    """Hasil rekomendasi LLM terstruktur."""
    summary: str = Field(..., description="Ringkasan kondisi kulit 2–3 kalimat")
    skin_type_note: str = Field("", description="Catatan tentang jenis kulit")
    findings_education: List[FindingEducation] = Field(default_factory=list)
    routine: List[RoutineStep] = Field(default_factory=list)
    recommended_ingredients: List[str] = Field(default_factory=list)
    avoid_ingredients: List[str] = Field(default_factory=list)
    lifestyle_tips: List[str] = Field(default_factory=list)
    medical_warning: Optional[str] = Field(
        None,
        description="Peringatan konsultasi dokter jika M03=Sedang-berat atau M06=Ya"
    )
    disclaimer: str = Field(
        default="Hasil ini bukan diagnosis medis. Konsultasikan dengan dokter atau dermatologis untuk penanganan klinis.",
        description="Disclaimer wajib"
    )
    generated_at: datetime = Field(default_factory=datetime.utcnow)


class RecommendationResponse(BaseModel):
    success: bool = True
    message: str = "Rekomendasi perawatan berhasil dibuat."
    data: RecommendationResult
