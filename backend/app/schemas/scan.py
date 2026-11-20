from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, ConfigDict, Field


class ProductRecommendation(BaseModel):
    id: str
    name: str
    brand: str
    category: str
    price: int
    match_reason: str
    image_url: Optional[str] = None


class ScanAnalysisResult(BaseModel):
    id: str = Field(..., description="ID unik scan")
    analyzed_at: datetime = Field(default_factory=datetime.utcnow)
    score: int = Field(..., ge=0, le=100, description="Skor kesehatan kulit total (0-100)")
    title: str = Field(..., description="Ringkasan diagnosis, misal 'Kondisi Kulit Baik'")
    skin_type: str = Field(..., description="Tipe kulit dominan: Normal, Oily, Dry, Combination, Sensitive")
    oil: int = Field(..., ge=0, le=100, description="Indeks sebum/minyak")
    pores: int = Field(..., ge=0, le=100, description="Indeks pori-pori tampak")
    acne: int = Field(..., ge=0, le=100, description="Indeks jerawat/komedo")
    redness: int = Field(..., ge=0, le=100, description="Indeks kemerahan/inflamasi")
    visual_findings: List[str] = Field(default_factory=list, description="Temuan visual spesifik")
    model_connected: bool = Field(default=True, description="Apakah dianalisis oleh model riil")
    is_demo: bool = Field(default=False, description="Flag jika menggunakan data tiruan")
    detection_counts: Dict[str, int] = Field(default_factory=dict, description="Jumlah bounding box per kelas")
    segmentation_areas: Dict[str, float] = Field(default_factory=dict, description="Rasio area mask per kelas")
    class_confidences: Dict[str, float] = Field(default_factory=dict, description="Confidence per kelas deteksi")
    skin_type_confidence: Optional[float] = Field(default=None, description="Tingkat keyakinan tipe kulit")
    model_version: Optional[str] = Field(default="v1.0.0", description="Versi model ML yang dipakai")
    recommended_ingredients: List[str] = Field(default_factory=list, description="Bahan aktif yang disarankan")
    avoid_ingredients: List[str] = Field(default_factory=list, description="Bahan aktif yang perlu dihindari")
    recommended_products: List[ProductRecommendation] = Field(
        default_factory=list, description="Produk terkurasi sesuai budget & masalah kulit"
    )
    image_url: Optional[str] = Field(default=None, description="Path foto di Supabase Storage (bucket skin-scans)")
    signed_image_url: Optional[str] = Field(default=None, description="Signed URL sementara untuk foto scan privat")
    meta: Dict[str, Any] = Field(default_factory=dict, description="Metadata tambahan (visual_boxes, ukuran gambar)")


class SignedImageUrlResponse(BaseModel):
    scan_id: str
    image_url: str
    signed_url: str
    expires_in: int


class ScanAnalysisResponse(BaseModel):
    success: bool = True
    message: str = "Analisis kulit berhasil dilakukan"
    data: ScanAnalysisResult


class ScanRecordCreate(BaseModel):
    """Payload untuk menyimpan hasil scan (mis. hasil inferensi on-device dari aplikasi mobile)."""
    id: Optional[str] = Field(default=None, max_length=64, description="ID dari klien; dibuat server bila kosong")
    analyzed_at: Optional[datetime] = None
    image_url: Optional[str] = Field(default=None, max_length=1024)
    score: int = Field(default=0, ge=0, le=100)
    title: str = Field(..., min_length=1, max_length=255)
    skin_type: str = Field(..., min_length=1, max_length=50)
    oil: int = Field(default=0, ge=0, le=100)
    pores: int = Field(default=0, ge=0, le=100)
    acne: int = Field(default=0, ge=0, le=100)
    redness: int = Field(default=0, ge=0, le=100)
    visual_findings: List[str] = Field(default_factory=list)
    recommended_ingredients: List[str] = Field(default_factory=list)
    avoid_ingredients: List[str] = Field(default_factory=list)
    detection_counts: Dict[str, int] = Field(default_factory=dict)
    segmentation_areas: Dict[str, float] = Field(default_factory=dict)
    class_confidences: Dict[str, float] = Field(default_factory=dict)
    model_version: Optional[str] = Field(default=None, max_length=50)
    model_connected: bool = False
    is_demo: bool = False
    meta: Dict[str, Any] = Field(default_factory=dict)


class ScanRecordUpdate(BaseModel):
    title: Optional[str] = Field(default=None, min_length=1, max_length=255)
    image_url: Optional[str] = Field(default=None, max_length=1024)
    meta: Optional[Dict[str, Any]] = None


class ScanRecordOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    analyzed_at: datetime
    image_url: Optional[str] = None
    score: int
    title: str
    skin_type: str
    oil: int
    pores: int
    acne: int
    redness: int
    visual_findings: List[str] = Field(default_factory=list)
    recommended_ingredients: List[str] = Field(default_factory=list)
    avoid_ingredients: List[str] = Field(default_factory=list)
    detection_counts: Dict[str, int] = Field(default_factory=dict)
    segmentation_areas: Dict[str, float] = Field(default_factory=dict)
    class_confidences: Dict[str, float] = Field(default_factory=dict)
    model_version: Optional[str] = None
    model_connected: bool = False
    is_demo: bool = False
    meta: Dict[str, Any] = Field(default_factory=dict)
