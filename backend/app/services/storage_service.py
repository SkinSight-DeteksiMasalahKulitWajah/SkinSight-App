"""Layanan upload, signed URL, dan hapus foto scan pada Supabase Storage (bucket privat `skin-scans`)."""
import logging
from typing import Optional
from urllib.parse import quote

import httpx

from app.core.config import settings

logger = logging.getLogger(__name__)

DEFAULT_BUCKET = "skin-scans"
MIME_TO_EXT = {
    "image/jpeg": "jpg",
    "image/jpg": "jpg",
    "image/png": "png",
    "image/webp": "webp",
}


class SupabaseStorageService:
    """Klien REST tipis untuk Supabase Storage bucket privat."""

    def __init__(self, bucket: str = DEFAULT_BUCKET):
        self.bucket = bucket

    @property
    def _base_url(self) -> str:
        return settings.SUPABASE_URL.rstrip("/")

    def _auth_headers(self, user_token: Optional[str] = None) -> Optional[dict]:
        """Pilih kredensial Storage: service role / secret key terlebih dahulu, fallback JWT user + anon key."""
        service_key = (settings.SUPABASE_SERVICE_ROLE_KEY or "").strip()
        if service_key and not service_key.startswith("YOUR_"):
            return {
                "apikey": service_key,
                "Authorization": f"Bearer {service_key}",
            }
        anon_key = (settings.SUPABASE_ANON_KEY or "").strip()
        if user_token and anon_key and not anon_key.startswith("YOUR_"):
            return {
                "apikey": anon_key,
                "Authorization": f"Bearer {user_token}",
            }
        return None

    async def upload_scan_photo(
        self,
        *,
        user_id: str,
        scan_id: str,
        content: bytes,
        content_type: str = "image/jpeg",
        user_token: Optional[str] = None,
    ) -> Optional[str]:
        """Upload foto scan ke `<user_id>/<scan_id>.<ext>` pada bucket privat `skin-scans`."""
        headers = self._auth_headers(user_token)
        if not headers or not self._base_url or not content:
            return None

        ext = MIME_TO_EXT.get(content_type.lower(), "jpg")
        object_path = f"{user_id}/{scan_id}.{ext}"
        encoded_path = quote(object_path, safe="/")
        url = f"{self._base_url}/storage/v1/object/{self.bucket}/{encoded_path}"

        try:
            async with httpx.AsyncClient(timeout=20) as client:
                resp = await client.post(
                    url,
                    content=content,
                    headers={
                        **headers,
                        "Content-Type": content_type,
                        "x-upsert": "true",
                    },
                )
            if resp.status_code in (200, 201):
                return object_path
            logger.warning("Upload Supabase Storage gagal (%s): %s", resp.status_code, resp.text[:200])
            return None
        except Exception as exc:
            logger.warning("Upload Supabase Storage error: %s", exc)
            return None

    async def create_signed_url(
        self,
        object_path: str,
        *,
        expires_in: int = 3600,
        user_token: Optional[str] = None,
    ) -> Optional[str]:
        """Buat Signed URL sementara untuk mengakses foto privat pada bucket `skin-scans`."""
        headers = self._auth_headers(user_token)
        if not headers or not self._base_url or not object_path:
            return None
        if object_path.startswith(("http://", "https://")):
            return object_path

        clean_path = object_path.lstrip("/")
        encoded_path = quote(clean_path, safe="/")
        url = f"{self._base_url}/storage/v1/object/sign/{self.bucket}/{encoded_path}"

        try:
            async with httpx.AsyncClient(timeout=15) as client:
                resp = await client.post(
                    url,
                    json={"expiresIn": expires_in},
                    headers={**headers, "Content-Type": "application/json"},
                )
            if resp.status_code == 200:
                data = resp.json()
                signed = data.get("signedURL") or data.get("signedUrl")
                if not signed:
                    return None
                if signed.startswith(("http://", "https://")):
                    return signed
                if not signed.startswith("/storage/v1"):
                    signed = f"/storage/v1{signed if signed.startswith('/') else '/' + signed}"
                return f"{self._base_url}{signed}"
            logger.warning("Signed URL gagal (%s): %s", resp.status_code, resp.text[:200])
            return None
        except Exception as exc:
            logger.warning("Signed URL error: %s", exc)
            return None

    async def delete_photo(
        self,
        object_path: str,
        *,
        user_token: Optional[str] = None,
    ) -> bool:
        """Hapus satu objek foto di bucket `skin-scans` (best-effort)."""
        headers = self._auth_headers(user_token)
        if not headers or not self._base_url or not object_path or object_path.startswith(("http://", "https://")):
            return False
        clean_path = object_path.lstrip("/")
        encoded_path = quote(clean_path, safe="/")
        url = f"{self._base_url}/storage/v1/object/{self.bucket}/{encoded_path}"
        try:
            async with httpx.AsyncClient(timeout=15) as client:
                resp = await client.delete(url, headers=headers)
            return resp.status_code in (200, 204, 404)
        except Exception as exc:
            logger.warning("Hapus objek Supabase Storage error: %s", exc)
            return False


storage_service = SupabaseStorageService()
