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
    │   │   ├── routes/        # Router endpoint (health, scan, users, journeys, dll.)
    │   │   ├── deps.py        # Dependency injection (db session, auth)
    │   │   └── api.py         # Root API router (/api/v1)
    │   ├── core/              # Config (pydantic-settings), database engine
    │   ├── models/            # SQLAlchemy ORM models
    │   ├── schemas/           # Pydantic request/response schemas
    │   ├── services/          # Business logic & ML inference pipeline
    │   └── main.py            # FastAPI entry point & CORS
    ├── alembic/               # Migrasi database async SQLAlchemy
    ├── tests/                 # Unit & integration tests
    ├── Dockerfile             # Container configuration
    ├── requirements.txt       # Dependencies
    ├── schema.sql             # SQL Script Supabase
    └── BACKEND_TASKS.md       # Roadmap & progress tracking
    ```
- [x] **1.2. Konfigurasi Lingkungan & Keamanan Dasar**
  - Setup konfigurasi `.env` via `pydantic-settings` (`DATABASE_URL`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `CORS_ORIGINS`).
  - Setup middleware **CORS** di `app/main.py`.

---

### Fase 2: Database & Skema Data (PostgreSQL / Supabase)
- [x] **2.1. Desain Skema Database**
  - Tabel `profiles`: Profil pengguna (nama, usia, tipe kulit, riwayat alergi).
  - Tabel `quiz_submissions`: Jawaban kuis awal preferensi & gaya hidup.
  - Tabel `scan_records`: Riwayat hasil scan wajah (overall score, metrik `oil`, `pores`, `acne`, `redness`, visual findings, model version).
  - Tabel `skin_journeys` & `journey_checkins`: Catatan perkembangan kulit dan check-in berkala.
  - Tabel `ingredients`: Database bahan aktif & kecocokan kondisi kulit.
  - Tabel `products`: Katalog skincare beserta rekomendasi bahan aktif & harga.
- [x] **2.2. Migrasi Database & Otomatisasi Anti-Pause**
  - Setup **Alembic** (`alembic.ini`, `alembic/env.py`, `script.py.mako`) untuk migrasi database terstruktur.
  - Menyediakan script manual SQL `schema.sql` untuk dijalankan langsung di Supabase SQL Editor.
  - Menyiapkan GitHub Action `keep-supabase-alive.yml` untuk menjaga project Supabase tetap aktif.

---

### Fase 3: Integrasi Model Machine Learning (Inference Pipeline)
*(Kolaborasi intensif dengan ML Engineer: Rafazl)*

- [x] **3.1. Buat Service Wrapper Inferensi ML (`app/services/ml_service.py`)**
  - Service `MLInferenceService` singleton yang memuat model saat startup.
  - Validasi MIME type (`image/jpeg`, `image/png`, `image/webp`) dan batas ukuran file (maksimal 10MB) pada layer route.
  - Parsing output prediksi ke format skema standar SkinSight:
    - *Skin type classification* (`Kombinasi`, `Berminyak`, `Kering`, `Normal`, `Sensitif`)
    - *Skin problem metrics* (`oil`, `pores`, `acne`, `redness` skala 0–100)
    - *Visual findings* dan analisis deskriptif
- [x] **3.2. Buat Mock / Fallback Inference**
  - Menyediakan fallback data simulasi (mode `USE_MOCK_ML=true`) agar tim Mobile dapat langsung mengintegrasikan upload gambar & menerima response analisis tanpa menunggu model final ditraining.
- [ ] **3.3. Integrasi Bobot Model Asli (.h5 / .tflite / ONNX)**
  - Menunggu penyerahan file model final dari tim Machine Learning (Rafazl).
  - Mengimplementasikan preprocessing tensor (resize, normalize) sesuai arsitektur model ML.

---

### Fase 4: Engine Rekomendasi Skincare & Bahan Aktif
- [x] **4.1. Logika Pemetaan Bahan Aktif (Baseline Rule Engine)**
  - Pemetaan rekomendasi bahan aktif berbasis kondisi dominan:
    - Masalah Jerawat/Minyak tinggi $\rightarrow$ Rekomendasi *Niacinamide*, *Salicylic Acid*, *Tea Tree*.
    - Masalah Kemerahan/Skin barrier $\rightarrow$ Rekomendasi *Centella Asiatica*, *Ceramide*, *Hyaluronic Acid*.
- [ ] **4.2. Filter Katalog Skincare Berdasarkan Database & Budget**
  - Query produk skincare dari database berdasarkan hasil analisis kulit.
  - Filter rentang harga (*budget filter*: `< Rp 50.000`, `Rp 50.000 - Rp 150.000`, `> Rp 150.000`).

---

### Fase 5: Implementasi REST API Endpoints

#### A. Health & System
- [x] `GET /health` : Health check status API & konektivitas sistem.
- [x] `GET /` : Redirect otomatis ke Swagger UI (`/docs`).

#### B. Pemindaian & Analisis Kulit (`/api/v1/scan`) — *Endpoint Utama*
- [x] `POST /api/v1/scan/analyze` : Menerima multipart image, memproses inferensi (mock/ML), dan mengembalikan metrik kesehatan kulit serta rekomendasi produk.
- [ ] `GET /api/v1/scan/history` : Mengambil daftar riwayat scan pengguna (paginasi).
- [ ] `GET /api/v1/scan/history/{scan_id}` : Mengambil detail satu hasil scan.

#### C. Autentikasi & Profil Pengguna (`/api/v1/users`)
- [ ] `POST /api/v1/users/sync` : Sinkronisasi data user dari Supabase Auth ke tabel `profiles`.
- [ ] `GET /api/v1/users/me` : Ambil profil pengguna beserta preferensi kulit.
- [ ] `PUT /api/v1/users/me` : Update data profil dan preferensi.

#### D. Kuis Gaya Hidup (`/api/v1/quiz`)
- [ ] `POST /api/v1/quiz/submit` : Simpan hasil kuis kondisi kulit awal pengguna.

#### E. Perjalanan Kulit / Journey (`/api/v1/journeys`)
- [ ] `GET /api/v1/journeys` : Ambil status journey aktif pengguna.
- [ ] `POST /api/v1/journeys/checkin` : Simpan check-in progres kulit berkala.

#### F. Katalog Produk & Edukasi (`/api/v1/catalog` & `/api/v1/education`)
- [ ] `GET /api/v1/catalog/products` : Filter produk berdasarkan tipe kulit, bahan aktif, dan batas harga.
- [ ] `GET /api/v1/education/articles` : Mengambil artikel dan tips perawatan kulit harian.

---

### Fase 6: Penyimpanan Gambar (Cloud Storage)
- [ ] **6.1. Setup Bucket Penyimpanan Wajah**
  - Konfigurasi Supabase Storage bucket (`skin-scans`) dengan RLS (Row Level Security).
  - Simpan URL gambar hasil upload ke dalam kolom `image_url` pada tabel `scan_records`.
  - Pastikan privasi data wajah terjaga (Protected / Signed URL).

---

### Fase 7: Pengujian, Dokumentasi, & Deployment
- [x] **7.1. Dokumentasi Swagger / OpenAPI**
  - OpenAPI & Swagger UI aktif di `/docs` dan ReDoc di `/redoc`.
  - Skema Pydantic `ScanAnalysisResponse` telah didefinisikan secara rapi.
- [x] **7.2. Automated Testing Baseline**
  - Unit test `backend/tests/test_health.py` untuk memvalidasi endpoint dasar.
- [ ] **7.3. Deployment & CI/CD**
  - Buat `Dockerfile` yang ringan dan efisien.
  - Setup deployment ke cloud platform (misal: Railway, Render, Fly.io, atau VPS).
  - Bagikan base URL API ke Bintang (Mobile Dev) untuk integrasi HTTP client.

---

## 🤝 Koordinasi Antar Peran
| Rekan Tim | Hal yang Perlu Dikoordinasikan | Status |
| :--- | :--- | :--- |
| **Bintang (Mobile Dev)** | Kontrak JSON request/response endpoint `/scan/analyze` dan integrasi HTTP client. | Siap diintegrasikan (Mock aktif) |
| **Rafazl (ML Engineer)** | Format file model final (`.h5`, `.tflite`, atau `onnx`), ukuran dimensi input citra, dan normalisasi tensor. | Menunggu model final |
| **Adam (Project Manager)** | Melaporkan progres pengerjaan milestone backend mingguan sesuai jadwal PBL. | Terus diperbarui |
