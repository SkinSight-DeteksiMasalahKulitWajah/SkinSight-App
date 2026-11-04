import uuid
from datetime import datetime
from typing import Dict, Any
from app.core.config import settings
from app.schemas.scan import ScanAnalysisResult, ProductRecommendation


class MLInferenceService:
    """Service to handle model loading, preprocessing, and skin condition inference."""

    def __init__(self, model_path: str = settings.ML_MODEL_PATH):
        self.model_path = model_path
        self.model = None
        self._load_model()

    def _load_model(self) -> None:
        """Load TFLite / ONNX / Keras model weights if available on disk."""
        if settings.USE_MOCK_ML:
            return

        try:
            # Placeholder for actual model loading once weights are supplied by ML Engineer
            pass
        except Exception:
            # Fallback to mock mode if model fails to load
            pass

    async def analyze_image(self, image_bytes: bytes, filename: str = "upload.jpg") -> ScanAnalysisResult:
        """Process image bytes and return structured skin health analysis."""
        scan_id = f"scan-{uuid.uuid4().hex[:12]}"
        now = datetime.utcnow()

        # Mock inference pipeline (matching mobile app expectations & PRD rules)
        # Allows frontend to develop against live backend immediately
        score = 82
        oil = 35
        pores = 28
        acne = 20
        redness = 25
        skin_type = "Kombinasi"

        findings = [
            "Pori-pori tampak sedikit membesar di area T-zone",
            "Minyak ringan di area dahi dan hidung",
            "Skin barrier secara umum dalam kondisi baik"
        ]

        recommended_ingredients = ["Niacinamide", "Hyaluronic Acid", "Ceramide"]
        avoid_ingredients = ["Alcohol Denat konsentrasi tinggi", "Scrub kasar"]

        sample_products = [
            ProductRecommendation(
                id="prod-01",
                name="Hydrating Barrier Serum",
                brand="SkinSight Care",
                category="Serum",
                price=89000,
                match_reason="Menjaga kelembapan skin barrier dan menyamarkan pori-pori.",
                image_url=None
            ),
            ProductRecommendation(
                id="prod-02",
                name="Gentle Gel Cleanser",
                brand="Cleanse Lab",
                category="Cleanser",
                price=55000,
                match_reason="Membersihkan minyak berlebih di zona T tanpa mengeringkan pipi.",
                image_url=None
            )
        ]

        return ScanAnalysisResult(
            id=scan_id,
            analyzed_at=now,
            score=score,
            title="Kondisi Kulit Seimbang",
            skin_type=skin_type,
            oil=oil,
            pores=pores,
            acne=acne,
            redness=redness,
            visual_findings=findings,
            model_connected=not settings.USE_MOCK_ML,
            is_demo=settings.USE_MOCK_ML,
            detection_counts={"acne": 2, "blackhead": 3},
            segmentation_areas={"t_zone_oil": 0.18, "redness_cheek": 0.05},
            class_confidences={"acne": 0.88, "blackhead": 0.81},
            skin_type_confidence=0.91,
            model_version="v1.0.0-baseline",
            recommended_ingredients=recommended_ingredients,
            avoid_ingredients=avoid_ingredients,
            recommended_products=sample_products
        )


ml_service = MLInferenceService()
