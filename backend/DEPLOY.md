# Panduan Menjalankan & Deploy Backend SkinSight (Self-Hosted / HP Sendiri)

## 1. Jalankan Lokal di PC / Laptop (Untuk HP Android Sendiri)
Pastikan file `backend/.env` sudah terisi (salin dari `.env.example`).

```powershell
cd backend
.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

### Menghubungkan HP Android Fisik ke Backend PC
- **Cara A — Via kabel USB (`adb reverse`, paling stabil)**:
  ```powershell
  adb reverse tcp:8000 tcp:8000
  ```
  Lalu jalankan Flutter dengan:
  ```powershell
  cd mobile
  flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
  ```
- **Cara B — Via Wi-Fi yang sama (IP LAN PC)**:
  Cek IP PC dengan `ipconfig` (mis. `192.168.1.10`), lalu jalankan Flutter:
  ```powershell
  cd mobile
  flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api/v1
  ```
- **Tanpa backend menyala sekalipun**: Aplikasi Flutter tetap menyimpan & memulihkan profil, kuesioner, riwayat scan + foto, journey, dan check-in langsung ke **Supabase** (via fallback SDK + RLS). Backend tetap dibutuhkan jika ingin memakai endpoint `POST /api/v1/recommendation/generate` (Gemini LLM) atau `/api/v1/scan/analyze`.

## 2. Jalankan via Docker / VPS Sendiri
```bash
cd backend
docker compose up -d --build
```
Cek status:
```bash
curl http://127.0.0.1:8000/api/v1/health
```
Dokumentasi API interaktif tersedia di `http://<host>:8000/docs`.
