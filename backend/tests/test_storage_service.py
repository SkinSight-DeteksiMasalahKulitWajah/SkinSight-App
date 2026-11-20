"""Unit tests untuk SupabaseStorageService (upload, signed URL, delete) dan extract_display_name Google."""
import pytest
import httpx

from app.core.config import settings
from app.core.security import extract_avatar_url, extract_display_name
from app.services.storage_service import SupabaseStorageService


def test_extract_google_display_name_and_avatar():
    assert extract_display_name({"full_name": "Budi Santoso"}, "budi@gmail.com") == "Budi Santoso"
    assert extract_display_name({"name": "Siti Aisyah"}, "siti@gmail.com") == "Siti Aisyah"
    assert extract_display_name({"given_name": "Ibra", "family_name": "A"}, "ibra@gmail.com") == "Ibra A"
    assert extract_display_name({}, "ibra.dev@gmail.com") == "ibra.dev"
    assert extract_avatar_url({"picture": "https://lh3.googleusercontent.com/a/avatar"}) == "https://lh3.googleusercontent.com/a/avatar"


@pytest.mark.asyncio
async def test_storage_upload_and_signed_url_mocked(monkeypatch):
    monkeypatch.setattr(settings, "SUPABASE_URL", "https://example.supabase.co")
    monkeypatch.setattr(settings, "SUPABASE_SERVICE_ROLE_KEY", "sb_secret_test_key")

    captured = []

    class _MockAsyncClient:
        def __init__(self, *args, **kwargs):
            pass

        async def __aenter__(self):
            return self

        async def __aexit__(self, *args):
            return False

        async def post(self, url, **kwargs):
            captured.append(("POST", url, kwargs))
            if "/object/sign/" in url:
                return httpx.Response(200, json={"signedURL": "/object/sign/skin-scans/u1/s1.jpg?token=abc"})
            return httpx.Response(200, json={"Key": "skin-scans/u1/s1.jpg"})

        async def delete(self, url, **kwargs):
            captured.append(("DELETE", url, kwargs))
            return httpx.Response(200, json={"message": "ok"})

    monkeypatch.setattr(httpx, "AsyncClient", _MockAsyncClient)

    svc = SupabaseStorageService()
    path = await svc.upload_scan_photo(
        user_id="u1", scan_id="s1", content=b"\xff\xd8\xff\xd9", content_type="image/jpeg"
    )
    assert path == "u1/s1.jpg"

    signed = await svc.create_signed_url(path, expires_in=600)
    assert signed == "https://example.supabase.co/storage/v1/object/sign/skin-scans/u1/s1.jpg?token=abc"

    deleted = await svc.delete_photo(path)
    assert deleted is True
    assert len(captured) == 3
