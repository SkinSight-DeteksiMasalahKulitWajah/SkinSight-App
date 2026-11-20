"""Automated tests untuk endpoint POST /api/v1/recommendation/generate (LLM + fallback)."""
import json
from types import SimpleNamespace

import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app
from app.services.llm_service import LLMService, llm_service

SAMPLE_PAYLOAD = {
    "scan": {
        "skin_type": "Oily",
        "skin_type_confidence": 0.9,
        "visual_findings": ["Acne", "PIH"],
        "detection_counts": {"Acne": 4, "PIH": 2},
        "segmentation_areas": {},
        "class_confidences": {"Acne": 0.82, "PIH": 0.74},
    },
    "quiz": {
        "M01": "Tidak",
        "M02": "Kadang",
        "M03": "Sedang-berat",
        "M04": "Tidak",
        "M05": "Kadang",
        "M06": "Tidak",
        "M07": "Acne|PIH",
    },
    "checkin_history": [],
    "language": "id",
}


@pytest.mark.asyncio
async def test_recommendation_generate_fallback_when_no_client(monkeypatch):
    monkeypatch.setattr(llm_service, "_client", None)
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        resp = await client.post("/api/v1/recommendation/generate", json=SAMPLE_PAYLOAD)

    assert resp.status_code == 200
    body = resp.json()
    assert body["success"] is True
    data = body["data"]
    assert "Berminyak" in data["summary"]
    assert len(data["findings_education"]) == 2
    assert len(data["routine"]) >= 4
    assert data["medical_warning"] is not None  # M03 == Sedang-berat


@pytest.mark.asyncio
async def test_recommendation_generate_with_mocked_gemini(monkeypatch):
    fake_json = {
        "summary": "Kulit berminyak dengan jerawat aktif dan bekas PIH.",
        "skin_type_note": "Gunakan pembersih gel lembut dan pelembap non-komedogenik.",
        "findings_education": [
            {
                "finding": "Acne",
                "finding_label": "Jerawat",
                "explanation": "Fokus menjaga pori bersih tanpa merusak barrier.",
                "care_tips": ["Cuci muka 2x sehari"],
                "timeline": "6-8 minggu",
            }
        ],
        "routine": [
            {
                "order": 1,
                "step_name": "Cleanser",
                "description": "Pembersih lembut pagi dan malam.",
                "ingredient_highlights": ["Salicylic Acid"],
                "when": "pagi & malam",
            }
        ],
        "recommended_ingredients": ["Niacinamide", "Salicylic Acid"],
        "avoid_ingredients": ["Scrub kasar"],
        "lifestyle_tips": ["Tidur cukup 7-9 jam"],
        "medical_warning": "Konsultasikan keluhan sedang-berat ke dokter kulit.",
        "disclaimer": "Hasil ini bukan diagnosis medis.",
    }

    class _FakeModels:
        async def generate_content(self, **kwargs):
            return SimpleNamespace(text=json.dumps(fake_json))

    fake_client = SimpleNamespace(aio=SimpleNamespace(models=_FakeModels()))
    monkeypatch.setattr(llm_service, "_client", fake_client)

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        resp = await client.post("/api/v1/recommendation/generate", json=SAMPLE_PAYLOAD)

    assert resp.status_code == 200
    data = resp.json()["data"]
    assert data["summary"] == fake_json["summary"]
    assert data["recommended_ingredients"] == ["Niacinamide", "Salicylic Acid"]
    assert data["routine"][0]["step_name"] == "Cleanser"


@pytest.mark.asyncio
async def test_recommendation_generate_recovers_on_invalid_json(monkeypatch):
    class _BrokenModels:
        async def generate_content(self, **kwargs):
            return SimpleNamespace(text="bukan json sama sekali")

    svc = LLMService()
    svc._client = SimpleNamespace(aio=SimpleNamespace(models=_BrokenModels()))
    monkeypatch.setattr("app.api.routes.recommendation.llm_service", svc)

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        resp = await client.post("/api/v1/recommendation/generate", json=SAMPLE_PAYLOAD)

    assert resp.status_code == 200
    assert resp.json()["success"] is True
    assert len(resp.json()["data"]["routine"]) >= 4
