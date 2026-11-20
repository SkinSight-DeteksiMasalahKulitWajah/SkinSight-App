"""Tes integrasi CRUD terhadap database asli (user uji dibersihkan otomatis)."""
import uuid
from datetime import datetime, timedelta, timezone

import pytest

from app.core.config import settings
from tests.conftest import new_user

pytestmark = pytest.mark.asyncio

SCAN = {
    "title": "Temuan: Acne",
    "skin_type": "Oily",
    "score": 0,
    "visual_findings": ["Acne"],
    "detection_counts": {"Acne": 3},
    "segmentation_areas": {},
    "class_confidences": {"Acne": 0.8},
    "model_version": "test-1",
    "model_connected": True,
    "meta": {"face_rect": [0.1, 0.1, 0.9, 0.9], "visual_boxes": []},
}


async def test_auth_required(make_client):
    anon = await make_client()
    for method, path in [
        ("get", "/api/v1/users/me"),
        ("get", "/api/v1/scan/history"),
        ("get", "/api/v1/journeys"),
        ("post", "/api/v1/quiz/submit"),
    ]:
        r = await getattr(anon, method)(path)
        assert r.status_code == 401, path


async def test_user_profile_crud(make_client):
    user = new_user()
    c = await make_client(user)

    r = await c.post("/api/v1/users/sync", json={"full_name": "Alea"})
    assert r.status_code == 200
    assert r.json()["email"] == user.email and r.json()["full_name"] in ("Tester", "Alea")

    r = await c.get("/api/v1/users/me")
    assert r.status_code == 200 and r.json()["id"] == user.id

    r = await c.put(
        "/api/v1/users/me",
        json={"full_name": "Alea K", "phone": "+62812", "dominant_skin_type": "Oily", "allergies": ["Retinol"]},
    )
    assert r.status_code == 200
    body = r.json()
    assert body["full_name"] == "Alea K" and body["phone"] == "+62812" and body["allergies"] == ["Retinol"]

    r = await c.delete("/api/v1/users/me")
    assert r.status_code == 200
    # Profil dibuat ulang otomatis (sync idempotent) tetapi bersih dari data lama.
    r = await c.get("/api/v1/users/me")
    assert r.json()["phone"] is None


async def test_scan_history_crud_and_isolation(make_client):
    owner, other = new_user("owner"), new_user("other")
    c, c2 = await make_client(owner), await make_client(other)

    now = datetime.now(timezone.utc)
    ids = []
    for i in range(3):
        sid = f"scan-test-{uuid.uuid4().hex[:8]}"
        ids.append(sid)
        r = await c.post("/api/v1/scan/records", json={**SCAN, "id": sid, "analyzed_at": (now - timedelta(days=i)).isoformat()})
        assert r.status_code == 201, r.text

    # idempotent: id sama -> update, bukan duplikat
    r = await c.post("/api/v1/scan/records", json={**SCAN, "id": ids[0], "title": "Diubah"})
    assert r.status_code == 201 and r.json()["title"] == "Diubah"

    r = await c.get("/api/v1/scan/history", params={"limit": 2})
    page = r.json()
    assert page["total"] == 3 and len(page["items"]) == 2
    assert page["items"][0]["id"] == ids[0]  # terbaru dulu
    assert page["items"][0]["meta"]["face_rect"] == [0.1, 0.1, 0.9, 0.9]

    day = (now - timedelta(days=1)).date().isoformat()
    r = await c.get("/api/v1/scan/history", params={"date": day})
    assert [i["id"] for i in r.json()["items"]] == [ids[1]]

    r = await c.patch(f"/api/v1/scan/history/{ids[1]}", json={"image_url": "uid/foto.jpg"})
    assert r.json()["image_url"] == "uid/foto.jpg"
    assert (await c.get(f"/api/v1/scan/history/{ids[1]}")).json()["image_url"] == "uid/foto.jpg"

    # user lain tidak boleh melihat / mengubah / menimpa
    assert (await c2.get(f"/api/v1/scan/history/{ids[0]}")).status_code == 404
    assert (await c2.delete(f"/api/v1/scan/history/{ids[0]}")).status_code == 404
    assert (await c2.post("/api/v1/scan/records", json={**SCAN, "id": ids[0]})).status_code == 409
    assert (await c2.get("/api/v1/scan/history")).json()["total"] == 0

    assert (await c.delete(f"/api/v1/scan/history/{ids[2]}")).status_code == 200
    assert (await c.get("/api/v1/scan/history")).json()["total"] == 2
    assert (await c.delete("/api/v1/scan/history")).status_code == 200
    assert (await c.get("/api/v1/scan/history")).json()["total"] == 0


async def test_scan_analyze_saves_for_logged_in_user(make_client):
    user = new_user()
    c = await make_client(user)
    files = {"file": ("a.jpg", b"fake-image-bytes", "image/jpeg")}
    r = await c.post("/api/v1/scan/analyze", files=files, params={"budget": "mid"})
    assert r.status_code == 200, r.text
    result = r.json()["data"]
    scan_id = result["id"]
    assert (await c.get(f"/api/v1/scan/history/{scan_id}")).status_code == 200

    # tanpa simpan
    r = await c.post("/api/v1/scan/analyze", files=files, params={"save": "false"})
    assert (await c.get(f"/api/v1/scan/history/{r.json()['data']['id']}")).status_code == 404

    # anonim tetap bisa analisis, tapi tidak tersimpan
    anon = await make_client()
    r = await anon.post("/api/v1/scan/analyze", files=files)
    assert r.status_code == 200

    bad = await c.post("/api/v1/scan/analyze", files={"file": ("a.txt", b"x", "text/plain")})
    assert bad.status_code == 400


async def test_quiz_crud(make_client):
    c = await make_client(new_user())
    assert (await c.get("/api/v1/quiz/latest")).status_code == 404
    r = await c.post("/api/v1/quiz/submit", json={"answers": {"tidur": "7 jam", "air": 8}, "lifestyle_score": 70})
    assert r.status_code == 201
    qid = r.json()["id"]
    assert (await c.get("/api/v1/quiz/latest")).json()["answers"]["air"] == 8
    assert len((await c.get("/api/v1/quiz")).json()) == 1
    assert (await c.delete(f"/api/v1/quiz/{qid}")).status_code == 200
    assert (await c.get("/api/v1/quiz")).json() == []


async def test_journey_and_checkin_crud(make_client):
    owner, other = new_user("owner"), new_user("other")
    c, c2 = await make_client(owner), await make_client(other)

    jid = str(uuid.uuid4())
    r = await c.post(
        "/api/v1/journeys",
        json={"id": jid, "title": "Perjalanan Kulit", "target_concern": "Jerawat", "meta": {"answers": {"M01": "a"}}},
    )
    assert r.status_code == 201 and r.json()["id"] == jid and r.json()["checkins_count"] == 0
    assert (await c.post("/api/v1/journeys", json={"id": jid, "title": "dup"})).status_code == 409

    r = await c.post("/api/v1/journeys/checkin", json={"journey_id": jid, "condition_rating": 4, "notes": "membaik", "meta": {"week": 1}})
    assert r.status_code == 201
    cid = r.json()["id"]
    assert (await c.post("/api/v1/journeys/checkin", json={"journey_id": jid, "condition_rating": 9})).status_code == 422
    # user lain tidak bisa menambah check-in ke journey orang lain
    assert (await c2.post("/api/v1/journeys/checkin", json={"journey_id": jid})).status_code == 404

    detail = (await c.get(f"/api/v1/journeys/{jid}")).json()
    assert detail["checkins_count"] == 1 and detail["checkins"][0]["meta"] == {"week": 1}
    assert (await c2.get(f"/api/v1/journeys/{jid}")).status_code == 404

    r = await c.put(f"/api/v1/journeys/{jid}", json={"title": "Baru", "is_pinned": True, "status": "completed"})
    assert r.json()["title"] == "Baru" and r.json()["is_pinned"] is True and r.json()["status"] == "completed"
    assert (await c.put(f"/api/v1/journeys/{jid}", json={"status": "ngawur"})).status_code == 422
    assert (await c.put(f"/api/v1/journeys/checkin/{cid}", json={"condition_rating": 5})).json()["condition_rating"] == 5

    assert [j["id"] for j in (await c.get("/api/v1/journeys", params={"status": "completed"})).json()] == [jid]

    # soft delete -> hilang dari daftar, ada dengan include_deleted, bisa dipulihkan
    assert (await c.delete(f"/api/v1/journeys/{jid}")).status_code == 200
    assert (await c.get("/api/v1/journeys")).json() == []
    deleted = (await c.get("/api/v1/journeys", params={"include_deleted": "true"})).json()
    assert deleted[0]["deleted_at"] is not None and deleted[0]["is_pinned"] is False
    assert (await c.post(f"/api/v1/journeys/{jid}/restore")).json()["deleted_at"] is None

    assert (await c.delete(f"/api/v1/journeys/checkin/{cid}")).status_code == 200
    assert (await c.get(f"/api/v1/journeys/{jid}")).json()["checkins_count"] == 0
    assert (await c.delete(f"/api/v1/journeys/{jid}", params={"permanent": "true"})).status_code == 200
    assert (await c.get(f"/api/v1/journeys/{jid}")).status_code == 404


async def test_catalog_filters_and_recommendations(make_client):
    c = await make_client(new_user())

    allp = (await c.get("/api/v1/catalog/products", params={"limit": 100})).json()
    assert allp["total"] >= 12

    low = (await c.get("/api/v1/catalog/products", params={"budget": "low", "limit": 100})).json()["items"]
    mid = (await c.get("/api/v1/catalog/products", params={"budget": "mid", "limit": 100})).json()["items"]
    high = (await c.get("/api/v1/catalog/products", params={"budget": "high", "limit": 100})).json()["items"]
    assert low and mid and high
    assert all(p["price"] < 50_000 for p in low)
    assert all(50_000 <= p["price"] <= 150_000 for p in mid)
    assert all(p["price"] > 150_000 for p in high)

    nia = (await c.get("/api/v1/catalog/products", params={"ingredient": "niacinamide", "limit": 100})).json()["items"]
    assert nia and all("Niacinamide" in p["ingredients"] for p in nia)

    oily = (await c.get("/api/v1/catalog/products", params={"skin_type": "Oily", "limit": 100})).json()
    assert oily["total"] > 0
    cat = (await c.get("/api/v1/catalog/products", params={"category": "serum", "limit": 100})).json()["items"]
    assert cat and all(p["category"] == "Serum" for p in cat)

    detail = (await c.get(f"/api/v1/catalog/products/{nia[0]['id']}")).json()
    assert detail["id"] == nia[0]["id"]
    assert (await c.get(f"/api/v1/catalog/products/{uuid.uuid4()}")).status_code == 404

    ings = (await c.get("/api/v1/catalog/ingredients", params={"concern": "Jerawat"})).json()
    assert {i["name"] for i in ings} >= {"Niacinamide", "Salicylic Acid"}

    # rekomendasi dari scan user
    assert (await c.get("/api/v1/catalog/recommendations")).status_code == 404
    await c.post(
        "/api/v1/scan/records",
        json={**SCAN, "id": f"scan-test-{uuid.uuid4().hex[:8]}", "recommended_ingredients": ["Niacinamide", "Salicylic Acid"]},
    )
    recs = (await c.get("/api/v1/catalog/recommendations", params={"budget": "low"})).json()
    assert recs and all(p["price"] < 50_000 and p["match_reason"] for p in recs)


async def test_catalog_and_education_admin_crud(make_client, monkeypatch):
    admin, normal = new_user("admin"), new_user("normal")
    monkeypatch.setattr(settings, "ADMIN_EMAILS", f"{admin.email}")
    a, n = await make_client(admin), await make_client(normal)
    tag = uuid.uuid4().hex[:8]

    # non-admin ditolak
    assert (await n.post("/api/v1/catalog/products", json={"name": "x", "brand": "y", "category": "Serum", "price": 1})).status_code == 403
    assert (await n.post("/api/v1/education/articles", json={"slug": f"s-{tag}", "topic": "Acne", "title": "t"})).status_code == 403

    # produk
    r = await a.post(
        "/api/v1/catalog/products",
        json={"name": f"Uji {tag}", "brand": "Test", "category": "Serum", "price": 12345, "ingredient_names": ["Niacinamide"]},
    )
    assert r.status_code == 201, r.text
    pid = r.json()["id"]
    assert r.json()["ingredients"] == ["Niacinamide"]
    r = await a.put(f"/api/v1/catalog/products/{pid}", json={"price": 20000, "ingredient_names": ["Ceramide", "Retinol"]})
    assert r.json()["price"] == 20000 and sorted(r.json()["ingredients"]) == ["Ceramide", "Retinol"]
    assert (await a.put(f"/api/v1/catalog/products/{pid}", json={"ingredient_names": ["TidakAda"]})).status_code == 422
    assert (await a.delete(f"/api/v1/catalog/products/{pid}")).status_code == 200
    assert (await a.get(f"/api/v1/catalog/products/{pid}")).status_code == 404

    # bahan aktif
    r = await a.post("/api/v1/catalog/ingredients", json={"name": f"Bahan {tag}", "good_for": ["Uji"]})
    assert r.status_code == 201
    iid = r.json()["id"]
    assert (await a.post("/api/v1/catalog/ingredients", json={"name": f"bahan {tag}"})).status_code == 409
    assert (await a.put(f"/api/v1/catalog/ingredients/{iid}", json={"description": "d"})).json()["description"] == "d"
    assert (await a.delete(f"/api/v1/catalog/ingredients/{iid}")).status_code == 200

    # artikel
    slug = f"uji-{tag}"
    r = await a.post("/api/v1/education/articles", json={"slug": slug, "topic": "Acne", "title": "Artikel uji", "key_points": ["a"]})
    assert r.status_code == 201
    aid = r.json()["id"]
    assert (await a.post("/api/v1/education/articles", json={"slug": slug, "topic": "Acne", "title": "dup"})).status_code == 409
    assert (await n.get(f"/api/v1/education/articles/{slug}")).json()["id"] == aid  # publik, lewat slug
    assert (await n.get(f"/api/v1/education/articles/{aid}")).json()["slug"] == slug  # lewat uuid
    assert (await a.put(f"/api/v1/education/articles/{aid}", json={"is_published": False})).json()["is_published"] is False
    assert (await n.get(f"/api/v1/education/articles/{slug}")).status_code == 404
    assert (await a.delete(f"/api/v1/education/articles/{aid}")).status_code == 200


async def test_education_listing(make_client):
    c = await make_client()
    page = (await c.get("/api/v1/education/articles", params={"limit": 3})).json()
    assert page["total"] >= 6 and len(page["items"]) == 3
    acne = (await c.get("/api/v1/education/articles", params={"topic": "acne"})).json()
    assert acne["total"] >= 2 and all(i["topic"] == "Acne" for i in acne["items"])
    found = (await c.get("/api/v1/education/articles", params={"q": "sunscreen"})).json()
    assert found["total"] >= 1


async def test_health_reports_database(make_client):
    r = await (await make_client()).get("/api/v1/health")
    assert r.status_code == 200 and r.json()["database"] == "ok"
