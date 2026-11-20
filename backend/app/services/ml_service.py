"""Service wrapper inferensi Machine Learning (LiteRT / TFLite YOLO11 + fallback mock).

Pipeline inferensi asli menyelaraskan model `all_conditions_detect_float32.tflite`:
- Decode citra & perbaiki orientasi EXIF (Pillow)
- Letterbox 640x640 dengan padding abu-abu (114/255.0)
- Tensor float32 [1, 3, 640, 640] (NCHW) atau [1, 640, 640, 3] (NHWC) sesuai model
- Decode output YOLO [1, 9, 8400] (4 bbox + 5 kelas: Acne, PIH, Dark Circle, Redness, Wrinkle)
- Per-class NMS (IoU 0.70, conf >= 0.05) -> metrik + visual findings + rekomendasi bahan aktif
"""
from __future__ import annotations

import io
import logging
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import numpy as np
from PIL import Image, ImageOps

from app.core.config import settings
from app.schemas.scan import ProductRecommendation, ScanAnalysisResult
from app.services.recommendation import recommend_ingredients

logger = logging.getLogger(__name__)

CLASS_NAMES = ["Acne", "PIH", "Dark Circle", "Redness", "Wrinkle"]
MODEL_VERSION_REAL = "skinsight-yolo11n-litert-all-conditions-v1"
MODEL_VERSION_MOCK = "v1.0.0-baseline-mock"
INPUT_SIZE = 640
CONF_THRESHOLD = 0.05
NMS_IOU_THRESHOLD = 0.70
MAX_DETECTIONS = 300


def _load_interpreter_class():
    """Muat Interpreter dari ai-edge-litert, tflite-runtime, atau tensorflow.lite."""
    try:
        from ai_edge_litert.interpreter import Interpreter  # type: ignore

        return Interpreter
    except ImportError:
        pass
    try:
        from tflite_runtime.interpreter import Interpreter  # type: ignore

        return Interpreter
    except ImportError:
        pass
    try:
        import tensorflow as tf  # type: ignore

        return tf.lite.Interpreter
    except ImportError:
        return None


def _resolve_model_path(configured_path: str) -> Optional[Path]:
    """Cari file bobot model di beberapa lokasi standar (backend/models & mobile/assets/ml_models)."""
    backend_root = Path(__file__).resolve().parents[2]
    repo_root = backend_root.parent
    raw = Path(configured_path)
    candidates = [
        raw,
        backend_root / raw,
        backend_root / "models" / "all_conditions_detect_float32.tflite",
        repo_root / "mobile" / "assets" / "ml_models" / "all_conditions_detect_float32.tflite",
    ]
    for candidate in candidates:
        if candidate.is_file():
            return candidate
    return None


def _letterbox_image(image: Image.Image, target_size: int = INPUT_SIZE) -> Tuple[np.ndarray, float, int, int]:
    """Resize proporsional ke target_size x target_size dengan padding abu-abu 114."""
    src_w, src_h = image.size
    scale = min(target_size / max(src_w, 1), target_size / max(src_h, 1))
    new_w = max(1, min(target_size, round(src_w * scale)))
    new_h = max(1, min(target_size, round(src_h * scale)))
    pad_x = target_size - new_w
    pad_y = target_size - new_h
    left = round(pad_x / 2 - 0.1)
    top = round(pad_y / 2 - 0.1)

    resized = image.resize((new_w, new_h), Image.Resampling.BILINEAR)
    canvas = Image.new("RGB", (target_size, target_size), (114, 114, 114))
    canvas.paste(resized, (left, top))
    arr = np.asarray(canvas, dtype=np.float32) / 255.0  # (H, W, 3)
    return arr, scale, left, top


def _compute_iou(box: np.ndarray, others: np.ndarray) -> np.ndarray:
    ix1 = np.maximum(box[0], others[:, 0])
    iy1 = np.maximum(box[1], others[:, 1])
    ix2 = np.minimum(box[2], others[:, 2])
    iy2 = np.minimum(box[3], others[:, 3])
    inter = np.maximum(0.0, ix2 - ix1) * np.maximum(0.0, iy2 - iy1)
    area_a = max(0.0, (box[2] - box[0]) * (box[3] - box[1]))
    area_b = np.maximum(0.0, (others[:, 2] - others[:, 0]) * (others[:, 3] - others[:, 1]))
    union = area_a + area_b - inter
    return np.where(union > 0.0, inter / union, 0.0)


def _decode_yolo_detections(
    raw_output: np.ndarray,
    *,
    src_w: int,
    src_h: int,
    scale: float,
    left: int,
    top: int,
    conf_threshold: float = CONF_THRESHOLD,
    iou_threshold: float = NMS_IOU_THRESHOLD,
) -> Tuple[Dict[str, int], Dict[str, float], List[dict]]:
    """Decode output YOLO [1, 9, 8400] (atau [1, 8400, 9]) + per-class NMS."""
    arr = np.squeeze(raw_output, axis=0)
    if arr.ndim != 2:
        raise ValueError(f"Bentuk output YOLO tidak valid: {raw_output.shape}")

    expected_ch = 4 + len(CLASS_NAMES)
    if arr.shape[0] == expected_ch:
        preds = arr.T  # (8400, 9)
    elif arr.shape[1] == expected_ch:
        preds = arr
    else:
        raise ValueError(f"Jumlah channel YOLO {arr.shape} tidak cocok dengan {expected_ch}.")

    boxes_xywh = preds[:, :4]
    class_scores = preds[:, 4:expected_ch]
    class_ids = np.argmax(class_scores, axis=1)
    scores = class_scores[np.arange(len(preds)), class_ids]

    mask = np.isfinite(scores) & (scores >= conf_threshold)
    boxes_xywh = boxes_xywh[mask]
    class_ids = class_ids[mask]
    scores = scores[mask]

    counts: Dict[str, int] = {name: 0 for name in CLASS_NAMES}
    confidences: Dict[str, float] = {}
    visual_boxes: List[dict] = []

    if len(scores) == 0:
        return counts, confidences, visual_boxes

    # Skala koordinat ternormalisasi [0..1] ke ruang letterbox 640x640
    if float(np.max(boxes_xywh)) <= 2.0:
        boxes_xywh = boxes_xywh * float(INPUT_SIZE)

    cx, cy, bw, bh = boxes_xywh[:, 0], boxes_xywh[:, 1], boxes_xywh[:, 2], boxes_xywh[:, 3]
    valid = (bw > 0) & (bh > 0) & np.isfinite(cx) & np.isfinite(cy) & np.isfinite(bw) & np.isfinite(bh)
    if not np.any(valid):
        return counts, confidences, visual_boxes

    cx, cy, bw, bh = cx[valid], cy[valid], bw[valid], bh[valid]
    class_ids = class_ids[valid]
    scores = scores[valid]

    xyxy = np.stack([cx - bw / 2.0, cy - bh / 2.0, cx + bw / 2.0, cy + bh / 2.0], axis=1)

    kept_indices: List[int] = []
    for cls_idx in range(len(CLASS_NAMES)):
        cls_mask = np.where(class_ids == cls_idx)[0]
        if len(cls_mask) == 0:
            continue
        order = cls_mask[np.argsort(-scores[cls_mask])]
        while len(order) > 0 and len(kept_indices) < MAX_DETECTIONS:
            current = int(order[0])
            kept_indices.append(current)
            if len(order) == 1:
                break
            ious = _compute_iou(xyxy[current], xyxy[order[1:]])
            order = order[1:][ious <= iou_threshold]

    kept_indices.sort(key=lambda idx: float(scores[idx]), reverse=True)
    for idx in kept_indices[:MAX_DETECTIONS]:
        x1 = max(0.0, min(float(src_w), (float(xyxy[idx, 0]) - left) / scale))
        y1 = max(0.0, min(float(src_h), (float(xyxy[idx, 1]) - top) / scale))
        x2 = max(0.0, min(float(src_w), (float(xyxy[idx, 2]) - left) / scale))
        y2 = max(0.0, min(float(src_h), (float(xyxy[idx, 3]) - top) / scale))
        if x2 <= x1 or y2 <= y1:
            continue
        label = CLASS_NAMES[int(class_ids[idx])]
        score = round(float(scores[idx]), 4)
        counts[label] += 1
        confidences[label] = max(confidences.get(label, 0.0), score)
        visual_boxes.append(
            {
                "label": label,
                "score": score,
                "rect": [
                    round(x1 / src_w, 4),
                    round(y1 / src_h, 4),
                    round(x2 / src_w, 4),
                    round(y2 / src_h, 4),
                ],
            }
        )

    return counts, confidences, visual_boxes


def _derive_metrics(counts: Dict[str, int]) -> Tuple[int, int, int, int, int, str]:
    """Konversi jumlah deteksi YOLO ke metrik ringkas (score, oil, pores, acne, redness, skin_type)."""
    acne_cnt = counts.get("Acne", 0)
    pih_cnt = counts.get("PIH", 0)
    redness_cnt = counts.get("Redness", 0)
    wrinkle_cnt = counts.get("Wrinkle", 0)
    dark_circle_cnt = counts.get("Dark Circle", 0)

    acne = min(100, acne_cnt * 12)
    redness = min(100, redness_cnt * 18)
    oil = min(100, 20 + acne_cnt * 6 + pih_cnt * 3)
    pores = min(100, 18 + acne_cnt * 4 + wrinkle_cnt * 5)

    penalty = min(65, acne_cnt * 4 + pih_cnt * 3 + redness_cnt * 5 + wrinkle_cnt * 3 + dark_circle_cnt * 2)
    score = max(35, 95 - penalty)

    if redness >= 45:
        skin_type = "Sensitif"
    elif acne >= 45 or oil >= 65:
        skin_type = "Berminyak"
    elif wrinkle_cnt >= 3 and acne == 0:
        skin_type = "Kering"
    elif acne > 0 or pih_cnt > 0:
        skin_type = "Kombinasi"
    else:
        skin_type = "Normal"

    return score, oil, pores, acne, redness, skin_type


class MLInferenceService:
    """Service untuk pemuatan model LiteRT/TFLite, preprocessing, dan inferensi kondisi kulit."""

    def __init__(self, model_path: str = settings.ML_MODEL_PATH):
        self.configured_model_path = model_path
        self.resolved_model_path: Optional[Path] = None
        self.interpreter = None
        self._input_details = None
        self._output_details = None
        self._load_model()

    @property
    def is_model_loaded(self) -> bool:
        return self.interpreter is not None

    def _load_model(self) -> None:
        """Muat bobot model `.tflite` (LiteRT) saat startup bila `USE_MOCK_ML=false`."""
        if settings.USE_MOCK_ML:
            logger.info("USE_MOCK_ML=true; MLInferenceService berjalan dalam mode mock.")
            return

        interpreter_cls = _load_interpreter_class()
        if interpreter_cls is None:
            logger.warning("Runtime LiteRT/TFLite tidak terpasang; fallback ke mode mock.")
            return

        resolved = _resolve_model_path(self.configured_model_path)
        if resolved is None:
            logger.warning("File model ML tidak ditemukan (%s); fallback ke mode mock.", self.configured_model_path)
            return

        try:
            interpreter = interpreter_cls(model_path=str(resolved))
            interpreter.allocate_tensors()
            self.interpreter = interpreter
            self._input_details = interpreter.get_input_details()
            self._output_details = interpreter.get_output_details()
            self.resolved_model_path = resolved
            logger.info("Model ML berhasil dimuat: %s", resolved)
        except Exception as exc:
            logger.warning("Gagal memuat model ML (%s); fallback ke mode mock.", exc)
            self.interpreter = None

    def _run_tflite(self, image_bytes: bytes) -> Tuple[Dict[str, int], Dict[str, float], List[dict], int, int]:
        image = Image.open(io.BytesIO(image_bytes))
        image = ImageOps.exif_transpose(image).convert("RGB")
        src_w, src_h = image.size

        hwc, scale, left, top = _letterbox_image(image, INPUT_SIZE)
        in_detail = self._input_details[0]
        in_shape = tuple(int(d) for d in in_detail["shape"])

        if len(in_shape) == 4 and in_shape[1] == 3:
            tensor = np.transpose(hwc, (2, 0, 1))[np.newaxis, ...].astype(np.float32)  # NCHW
        else:
            tensor = hwc[np.newaxis, ...].astype(np.float32)  # NHWC

        self.interpreter.set_tensor(in_detail["index"], tensor)
        self.interpreter.invoke()
        raw_output = self.interpreter.get_tensor(self._output_details[0]["index"])
        counts, confidences, visual_boxes = _decode_yolo_detections(
            raw_output,
            src_w=src_w,
            src_h=src_h,
            scale=scale,
            left=left,
            top=top,
        )
        return counts, confidences, visual_boxes, src_w, src_h

    async def analyze_image(self, image_bytes: bytes, filename: str = "upload.jpg") -> ScanAnalysisResult:
        """Proses bytes gambar dan kembalikan hasil analisis kulit terstruktur."""
        scan_id = f"scan-{uuid.uuid4().hex[:12]}"
        now = datetime.now(timezone.utc)

        if self.interpreter is not None and not settings.USE_MOCK_ML:
            try:
                counts, confidences, visual_boxes, src_w, src_h = self._run_tflite(image_bytes)
                visual_findings = [name for name in CLASS_NAMES if counts.get(name, 0) > 0]
                score, oil, pores, acne, redness, skin_type = _derive_metrics(counts)
                recommended_ingredients, avoid_ingredients = recommend_ingredients(
                    acne=acne, oil=oil, redness=redness, pores=pores, skin_type=skin_type
                )
                title = (
                    f"Temuan: {', '.join(visual_findings)}"
                    if visual_findings
                    else "Tidak ada temuan visual dominan"
                )
                return ScanAnalysisResult(
                    id=scan_id,
                    analyzed_at=now,
                    score=score,
                    title=title,
                    skin_type=skin_type,
                    oil=oil,
                    pores=pores,
                    acne=acne,
                    redness=redness,
                    visual_findings=visual_findings,
                    model_connected=True,
                    is_demo=False,
                    detection_counts=counts,
                    segmentation_areas={},
                    class_confidences=confidences,
                    skin_type_confidence=0.86,
                    model_version=MODEL_VERSION_REAL,
                    recommended_ingredients=recommended_ingredients,
                    avoid_ingredients=avoid_ingredients,
                    recommended_products=[],
                    meta={
                        "image_width": src_w,
                        "image_height": src_h,
                        "visual_boxes": visual_boxes,
                        "filename": filename,
                    },
                )
            except Exception as exc:
                logger.warning("Inferensi TFLite gagal (%s); fallback ke mode mock.", exc)

        # Fallback mock inference
        score, oil, pores, acne, redness = 82, 35, 28, 20, 25
        skin_type = "Kombinasi"
        findings = ["Acne", "PIH"]
        recommended_ingredients, avoid_ingredients = recommend_ingredients(
            acne=acne, oil=oil, redness=redness, pores=pores, skin_type=skin_type
        )
        sample_products = [
            ProductRecommendation(
                id="prod-01",
                name="Hydrating Barrier Serum",
                brand="SkinSight Care",
                category="Serum",
                price=89000,
                match_reason="Menjaga kelembapan skin barrier dan menyamarkan pori-pori.",
                image_url=None,
            ),
            ProductRecommendation(
                id="prod-02",
                name="Gentle Gel Cleanser",
                brand="Cleanse Lab",
                category="Cleanser",
                price=55000,
                match_reason="Membersihkan minyak berlebih di zona T tanpa mengeringkan pipi.",
                image_url=None,
            ),
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
            model_connected=False,
            is_demo=True,
            detection_counts={"Acne": 2, "PIH": 1, "Dark Circle": 0, "Redness": 0, "Wrinkle": 0},
            segmentation_areas={},
            class_confidences={"Acne": 0.88, "PIH": 0.81},
            skin_type_confidence=0.91,
            model_version=MODEL_VERSION_MOCK,
            recommended_ingredients=recommended_ingredients,
            avoid_ingredients=avoid_ingredients,
            recommended_products=sample_products,
            meta={"filename": filename},
        )


ml_service = MLInferenceService()
