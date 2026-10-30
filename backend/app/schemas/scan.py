from datetime import datetime
from typing import Dict, List, Optional
from pydantic import BaseModel, Field


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


class ScanAnalysisResponse(BaseModel):
    success: bool = True
    message: str = "Analisis kulit berhasil dilakukan"
    data: ScanAnalysisResult
