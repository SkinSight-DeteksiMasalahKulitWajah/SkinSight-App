"""Unit test inferensi ML nyata (LiteRT TFLite YOLO11) & mode fallback mock."""
import io

import numpy as np
import pytest
from PIL import Image

from app.core.config import settings
from app.services.ml_service import (
    CLASS_NAMES,
    MODEL_VERSION_MOCK,
    MODEL_VERSION_REAL,
    MLInferenceService,
    _decode_yolo_detections,
)


def _sample_jpeg_bytes(width: int = 320, height: int = 240) -> bytes:
    buf = io.BytesIO()
    Image.new("RGB", (width, height), (210, 175, 155)).save(buf, format="JPEG")
    return buf.getvalue()


@pytest.mark.asyncio
async def test_real_tflite_inference_loads_and_runs(monkeypatch):
    monkeypatch.setattr(settings, "USE_MOCK_ML", False)
    service = MLInferenceService(model_path="models/all_conditions_detect_float32.tflite")
    assert service.is_model_loaded is True
    assert service.resolved_model_path is not None

    result = await service.analyze_image(_sample_jpeg_bytes(), filename="sample.jpg")
    assert result.model_connected is True
    assert result.is_demo is False
    assert result.model_version == MODEL_VERSION_REAL
    assert set(result.detection_counts.keys()) == set(CLASS_NAMES)
    assert 0 <= result.score <= 100
    assert result.meta.get("image_width") == 320
    assert result.meta.get("image_height") == 240
    assert len(result.recommended_ingredients) > 0


@pytest.mark.asyncio
async def test_mock_mode_fallback(monkeypatch):
    monkeypatch.setattr(settings, "USE_MOCK_ML", True)
    service = MLInferenceService(model_path="models/nonexistent.tflite")
    assert service.is_model_loaded is False

    result = await service.analyze_image(_sample_jpeg_bytes(), filename="mock.jpg")
    assert result.model_connected is False
    assert result.is_demo is True
    assert result.model_version == MODEL_VERSION_MOCK


def test_decode_yolo_detections_nms_and_box_scaling():
    # Bentuk output [1, 9, 8400]: dua box Acne bertumpuk + satu box PIH terpisah
    raw = np.zeros((1, 9, 8400), dtype=np.float32)
    # Anchor 0: Acne (class 0) di tengah, score 0.85
    raw[0, 0:4, 0] = [0.5, 0.5, 0.2, 0.2]
    raw[0, 4, 0] = 0.85
    # Anchor 1: Acne bertumpuk sangat dekat (harus ter-NMS), score 0.60
    raw[0, 0:4, 1] = [0.51, 0.51, 0.2, 0.2]
    raw[0, 4, 1] = 0.60
    # Anchor 2: PIH (class 1) di sudut lain, score 0.72
    raw[0, 0:4, 2] = [0.2, 0.2, 0.1, 0.1]
    raw[0, 5, 2] = 0.72

    counts, confs, boxes = _decode_yolo_detections(
        raw, src_w=640, src_h=640, scale=1.0, left=0, top=0
    )
    assert counts["Acne"] == 1
    assert counts["PIH"] == 1
    assert confs["Acne"] == pytest.approx(0.85, abs=1e-3)
    assert confs["PIH"] == pytest.approx(0.72, abs=1e-3)
    assert len(boxes) == 2
