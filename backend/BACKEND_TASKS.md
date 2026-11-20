# 📋 SkinSight Backend Development Roadmap & Task List

Dokumen ini merupakan panduan tugas dan rencana kerja teknis untuk **Muchammad Ibrahim A. A** (*Backend Developer*) dalam proyek **SkinSight**.

---

## 🎯 Ringkasan Peran & Tanggung Jawab Backend
Sebagai Backend Developer, tugas utama Anda adalah:
1. Menyediakan **REST API** yang menghubungkan aplikasi **Flutter (Frontend)** dengan model inferensi dari **Machine Learning Engineer**.
2. Mengelola **penyimpanan data** (database pengguna, riwayat scan, profil kulit, check-in harian, katalog produk/edukasi).
3. Mengelola **file/image storage** untuk foto scan wajah pengguna secara aman.
4. Menyediakan **dokumentasi kontrak API (OpenAPI/Swagger)** agar tim Mobile dapat melakukan integrasi dengan lancar.

---

## 📌 Checklist Tugas Berdasarkan Fase

### Fase 1: Setup Arsitektur & Lingkungan Kerja
- [x] **1.1. Inisialisasi Framework Backend**
  - Menggunakan **FastAPI (Python 3.10+)** dengan arsitektur modular (`api`, `core`, `models`, `schemas`, `services`).
  - Struktur folder di `/backend` sudah tertata:
    ```text
    backend/
    ├── app/
    │   ├── api/
    │   │   ├── routes/        # Router endpoint (health, scan, users, quiz, journeys, catalog, education, recommendation)
    │   │   ├── deps.py        # Dependency injection (db session, auth, admin)
    │   │   └── api.py         # Root API router (/api/v1)
    │   ├── core/              # Config (pydantic-settings), database engine, JWT security
    │   ├── models/            # SQLAlchemy ORM models
    │   ├── schemas/           # Pydantic request/response schemas
    │   ├── seed_data/         # Data awal katalog & artikel edukasi (JSON)
    │   ├── services/          # Business logic, ML inference, rule engine & LLM Gemini
    │   └── main.py            # FastAPI entry point & CORS
    ├── alembic/               # Migrasi database async SQLAlchemy (0001, 0002)
    ├── models/                # Bobot model ML (`all_conditions_detect_float32.tflite`)
    ├── scripts/               # Seed script (`python -m scripts.seed`)
    ├── tests/                 # Unit & integration tests (`test_health`, `test_api_crud`, `test_ml_service`, `test_recommendation`, `test_storage_service`, `test_database_url`)
    ├── Dockerfile             # Container configuration (+ `.dockerignore`, `docker-compose.yml`)
    ├── DEPLOY.md              # Panduan self-host / konek HP Android sendiri
    ├── requirements.txt       # Dependencies
    ├── schema.sql             # SQL Script Supabase (tabel + RLS)
    ├── supabase_storage_setup.sql # SQL bucket privat `skin-scans` + RLS storage
    └── BACKEND_TASKS.md       # Roadmap & progress tracking
    ```
- [x] **1.2. Konfigurasi Lingkungan & Keamanan Dasar**
  - Setup konfigurasi `.env` via `pydantic-settings` (`DATABASE_URL`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_JWT_SECRET`, `ADMIN_EMAILS`, `GEMINI_API_KEY`, `GEMINI_MODEL`, `CORS_ORIGINS`).
  - Setup middleware **CORS** di `app/main.py` dan verifikasi JWT Supabase di `app/core/security.py`.

---

### Fase 2: Database & Skema Data (PostgreSQL / Supabase)
- [x] **2.1. Desain Skema Database**
  - Tabel `profiles`: Profil pengguna (nama, telepon, avatar, gender, tanggal lahir, tipe kulit, keluhan, riwayat alergi).
  - Tabel `quiz_submissions`: Jawaban kuis awal preferensi & gaya hidup.
  - Tabel `scan_records`: Riwayat hasil scan wajah (overall score, metrik `oil`, `pores`, `acne`, `redness`, visual findings, metadata on-device `meta`, model version).
  - Tabel `skin_journeys` & `journey_checkins`: Catatan perkembangan kulit, pin/soft-delete, dan check-in berkala.
  - Tabel `ingredients` & `products` (+ pivot `product_ingredients`): Database bahan aktif & katalog skincare beserta harga.
  - Tabel `articles`: Konten artikel edukasi kulit berbasis topik & slug.
  - Seluruh 9 tabel + RLS sudah aktif di Supabase dan terisi data awal (`scripts/seed.py`: 9 bahan aktif, 12 produk, 6 artikel).
- [x] **2.2. Migrasi Database & Otomatisasi Anti-Pause**
  - Setup **Alembic** (`alembic.ini`, `alembic/env.py`, `0001_initial_schema.py`, `0002_crud_support.py`) untuk migrasi database terstruktur.
  - Menyediakan script manual SQL `schema.sql` untuk dijalankan langsung di Supabase SQL Editor.
  - Menyiapkan GitHub Action `.github/workflows/keep-supabase-alive.yml` untuk menjaga project Supabase tetap aktif.

---

### Fase 3: Integrasi Model Machine Learning (Inference Pipeline)
*(Kolaborasi intensif dengan ML Engineer: Rafazl)*

- [x] **3.1. Buat Service Wrapper Inferensi ML (`app/services/ml_service.py`)**
  - Service `MLInferenceService` singleton yang memuat model saat startup.
  - Validasi MIME type (`image/jpeg`, `image/png`, `image/webp`) dan batas ukuran file (maksimal 10MB) pada layer route (`app/api/routes/scan.py`).
  - Parsing output prediksi ke format skema standar SkinSight (`ScanAnalysisResult`):
    - *Skin type classification* (`Kombinasi`, `Berminyak`, `Kering`, `Normal`, `Sensitif`)
    - *Skin problem metrics* (`oil`, `pores`, `acne`, `redness` skala 0–100)
    - *Visual findings*, `detection_counts`, `segmentation_areas`, `class_confidences`, dan analisis deskriptif.
- [x] **3.2. Buat Mock / Fallback Inference**
  - Menyediakan fallback data simulasi (mode `USE_MOCK_ML=true`) agar tim Mobile dapat mengintegrasikan upload gambar & menerima response analisis.
- [x] **3.3. Integrasi Bobot Model Asli (`.tflite` LiteRT YOLO11) di Backend**
  - Bobot model `all_conditions_detect_float32.tflite` (YOLO11 5 kelas: `Acne`, `PIH`, `Dark Circle`, `Redness`, `Wrinkle`) sudah dipasang di `backend/models/` dan aktif dijalankan via `ai-edge-litert` (XNNPACK) saat `USE_MOCK_ML=false`.
  - Preprocessing EXIF + letterbox 640×640 + decode & per-class NMS (IoU 0.70, conf >= 0.05) sudah diimplementasikan dan terverifikasi di `app/services/ml_service.py` & `tests/test_ml_service.py`.

---

### Fase 4: Engine Rekomendasi Skincare & Bahan Aktif
- [x] **4.1. Logika Pemetaan Bahan Aktif (Baseline Rule Engine)**
  - Terimplementasi di `app/services/recommendation.py` (`recommend_ingredients`):
    - Masalah Jerawat/Minyak tinggi $\rightarrow$ Rekomendasi *Niacinamide*, *Salicylic Acid*, *Tea Tree*.
    - Masalah Kemerahan/Skin barrier $\rightarrow$ Rekomendasi *Centella Asiatica*, *Ceramide*, *Hyaluronic Acid*.
- [x] **4.2. Filter Katalog Skincare Berdasarkan Database & Budget**
  - Query produk skincare dari database (`product_query`, `find_recommended_products`) berdasarkan hasil analisis kulit & bahan aktif.
  - Filter rentang harga (*budget filter*: `low` `< Rp 50.000`, `mid` `Rp 50.000 - Rp 150.000`, `high` `> Rp 150.000`).
- [x] **4.3. Engine Rekomendasi Personal Berbasis LLM (Gemini API)**
  - Terimplementasi di `app/services/llm_service.py` (SDK terbaru `google-genai`, model `gemini-3.5-flash`) dan endpoint `POST /api/v1/recommendation/generate` (`app/api/routes/recommendation.py`).
  - Terverifikasi live dengan `GEMINI_API_KEY` + tetap menyediakan fallback statis otomatis bila API/jaringan tidak tersedia.

---

### Fase 5: Implementasi REST API Endpoints

#### A. Health & System
- [x] `GET /api/v1/health` : Health check status API & konektivitas database (`SELECT 1`).
- [x] `GET /` : Redirect otomatis ke Swagger UI (`/docs`).

#### B. Pemindaian & Analisis Kulit (`/api/v1/scan`) — *Endpoint Utama*
- [x] `POST /api/v1/scan/analyze` : Menerima multipart image, memproses inferensi (mock/ML), dan mengembalikan metrik kesehatan kulit serta rekomendasi produk.
- [x] `GET /api/v1/scan/history` : Mengambil daftar riwayat scan pengguna (paginasi + filter tanggal).
- [x] `GET /api/v1/scan/history/{scan_id}` : Mengambil detail satu hasil scan.

#### C. Autentikasi & Profil Pengguna (`/api/v1/users`)
- [x] `POST /api/v1/users/sync` : Sinkronisasi data user dari Supabase Auth ke tabel `profiles`.
- [x] `GET /api/v1/users/me` : Ambil profil pengguna beserta preferensi kulit.
- [x] `PUT /api/v1/users/me` : Update data profil dan preferensi.

#### D. Kuis Gaya Hidup (`/api/v1/quiz`)
- [x] `POST /api/v1/quiz/submit` : Simpan hasil kuis kondisi kulit awal pengguna.

#### E. Perjalanan Kulit / Journey (`/api/v1/journeys`)
- [x] `GET /api/v1/journeys` : Ambil daftar & status journey pengguna.
- [x] `POST /api/v1/journeys/checkin` : Simpan check-in progres kulit berkala.

#### F. Katalog Produk & Edukasi (`/api/v1/catalog` & `/api/v1/education`)
- [x] `GET /api/v1/catalog/products` : Filter produk berdasarkan tipe kulit, bahan aktif, dan batas harga.
- [x] `GET /api/v1/education/articles` : Mengambil artikel dan tips perawatan kulit harian.

#### G. Rekomendasi Personal LLM (`/api/v1/recommendation`)
- [x] `POST /api/v1/recommendation/generate` : Generate rekomendasi rutinitas & edukasi perawatan personal berbasis Google Gemini API (+ fallback statis).

#### Endpoint tambahan (CRUD lengkap)
- [x] Scan: `POST /api/v1/scan/records` (simpan hasil on-device, idempotent), `GET /api/v1/scan/history/{scan_id}/image-url` (Signed URL privat), `PATCH|DELETE /api/v1/scan/history/{scan_id}`, `DELETE /api/v1/scan/history`.
- [x] Users: `DELETE /api/v1/users/me`.
- [x] Quiz: `GET /api/v1/quiz`, `GET /api/v1/quiz/latest`, `DELETE /api/v1/quiz/{quiz_id}`.
- [x] Journeys: `POST /api/v1/journeys`, `GET|PUT|DELETE /api/v1/journeys/{journey_id}` (soft/permanent), `POST /api/v1/journeys/{journey_id}/restore`, `PUT|DELETE /api/v1/journeys/checkin/{checkin_id}`.
- [x] Catalog: `GET /api/v1/catalog/recommendations`, `GET /api/v1/catalog/ingredients`, `GET /api/v1/catalog/products/{product_id}`, `GET /api/v1/catalog/ingredients/{ingredient_id}`; admin CRUD (`POST|PUT|DELETE`) produk & bahan aktif (`ADMIN_EMAILS` di `.env`).
- [x] Education: `GET /api/v1/education/articles/{article_key}` (UUID/slug); admin CRUD (`POST|PUT|DELETE`) artikel.
- [x] Autentikasi: verifikasi JWT Supabase (`app/core/security.py`) pada semua endpoint data pengguna.
- [x] Sinkron mobile: profil, riwayat scan, kuesioner, journey & check-in (`mobile/lib/core/api`).

> Catatan: aplikasi mobile menjalankan inferensi on-device; hasilnya disimpan lewat `POST /api/v1/scan/records`.
> Foto disimpan di Supabase Storage (`supabase_storage_setup.sql`). Seed data contoh: `python -m scripts.seed`.

---

### Fase 6: Penyimpanan Gambar (Cloud Storage)
- [x] **6.1. Setup Bucket Penyimpanan Wajah (`skin-scans`) & Integrasi Mobile**
  - Bucket privat Supabase Storage (`skin-scans`, `public = false`) sudah aktif beserta 4 policy RLS per-user (`supabase_storage_setup.sql`).
  - Mobile (`mobile/lib/core/api/cloud_storage.dart` & `skin_history_repository.dart`) mengunggah foto ke `<user_id>/<scan_id>.jpg`, menyimpan path ke kolom `scan_records.image_url` lewat `POST /api/v1/scan/records` (dengan fallback langsung ke Supabase SDK), dan mengunduh foto secara terproteksi dengan sesi autentikasi pengguna.
- [x] **6.2. Upload Foto & Signed URL di Sisi Server (`POST /api/v1/scan/analyze`)**
  - Terimplementasi di `app/services/storage_service.py` dan terintegrasi di `app/api/routes/scan.py`: `POST /api/v1/scan/analyze` otomatis mengunggah foto ke bucket privat `skin-scans`, menyimpan `image_url`, dan mengembalikan `signed_image_url`.
  - Endpoint `GET /api/v1/scan/history/{scan_id}/image-url` aktif untuk menerbitkan Signed URL sementara, dan `DELETE /api/v1/scan/history/{scan_id}` ikut membersihkan objek di Storage.

---

### Fase 7: Pengujian, Dokumentasi, & Deployment
- [x] **7.1. Dokumentasi Swagger / OpenAPI**
  - OpenAPI & Swagger UI aktif di `/docs`, ReDoc di `/redoc`, dan skema JSON di `/api/v1/openapi.json` (25 path aktif).
  - Skema Pydantic lengkap (`ScanAnalysisResponse`, `SignedImageUrlResponse`, `RecommendationResponse`, `Page[...]`, dll.).
- [x] **7.2. Automated Testing (Unit & Integrasi CRUD)**
  - Unit test: `test_health.py`, `test_database_url.py`, `test_ml_service.py`, `test_recommendation.py`, `test_storage_service.py` (13/13 lulus).
  - Integration test CRUD langsung ke Supabase: `test_api_crud.py` + `conftest.py` (10/10 lulus; total 23/23 `pytest` lulus).
- [ ] **7.3. Deployment & CI/CD**
  - [x] Buat `Dockerfile` yang ringan & efisien (+ `.dockerignore`, `docker-compose.yml`, dan panduan self-host/HP sendiri di `backend/DEPLOY.md`).
  - [x] Setup GitHub Actions CI backend (`.github/workflows/backend-ci.yml`).
  - [ ] Deploy live ke server/VPS/cloud publik & set `API_BASE_URL` production *(saat ini memakai mode self-host / HP sendiri + fallback langsung ke Supabase)*.

---

## 🤝 Koordinasi Antar Peran
| Rekan Tim | Hal yang Perlu Dikoordinasikan | Status |
| :--- | :--- | :--- |
| **Bintang (Mobile Dev)** | Kontrak API CRUD, auth Google username, sinkronisasi dual-path (FastAPI + fallback Supabase), dan normalisasi `API_BASE_URL`. | Selesai & terintegrasi (Tinggal URL production jika deploy cloud) |
| **Rafazl (ML Engineer)** | Model `.tflite` YOLO11 sudah jalan di mobile (on-device) & backend (`ml_service.py`), plus rekomendasi LLM Gemini `gemini-3.5-flash` aktif. | Selesai & aktif |
| **Adam (Project Manager)** | Melaporkan progres pengerjaan milestone backend mingguan sesuai jadwal PBL. | Terus diperbarui |
