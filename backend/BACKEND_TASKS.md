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
  - Gunakan **FastAPI (Python)** — direkomendasikan karena integrasi native dengan model AI/ML (Python/TensorFlow/PyTorch) dan performa async tinggi.
  - Setup struktur folder di dalam `/backend`:
    ```text
    backend/
    ├── app/
    │   ├── api/
    │   │   ├── routes/        # Router endpoint (auth, scan, product, journey)
    │   │   └── deps.py        # Dependency injection (db, auth)
    │   ├── core/              # Config, security, database connection
    │   ├── models/            # SQLAlchemy / ORM models
    │   ├── schemas/           # Pydantic models (request & response contracts)
    │   ├── services/          # Business logic & ML inference caller
    │   └── main.py            # FastAPI entry point
    ├── tests/                 # Unit & integration tests (pytest)
    ├── Dockerfile             # Container configuration
    ├── requirements.txt       # Dependencies
    └── .env.example           # Environment variables template
    ```
- [x] **1.2. Konfigurasi Lingkungan & Keamanan Dasar**
  - Setup `.env` untuk konfigurasi: database URL, Supabase keys/JWT secret, storage bucket, dan model path.
  - Tambahkan middleware **CORS** agar aplikasi mobile (dan Flutter Web jika ada) bisa mengakses API tanpa kendala domain.

---

### Fase 2: Database & Skema Data (PostgreSQL / Supabase)
- [x] **2.1. Desain Skema Database**
  - Tabel `profiles`: Profil pengguna (nama, usia, tipe kulit dominan, riwayat alergi).
  - Tabel `quiz_submissions`: Jawaban kuis awal gaya hidup pengguna.
  - Tabel `scan_records`: Riwayat hasil scan:
    - ID, user_id, image_url, analyzed_at
    - Skor kesehatan kulit (overall score 0-100)
    - Nilai metrik: `oil`, `pores`, `acne`, `redness`
    - Visual findings (array of text: misal `["Kemerahan di pipi", "Komedo di hidung"]`)
    - Metadata model: `model_version`, `confidence_score`
  - Tabel `skin_journeys` & `journey_checkins`: Catatan perkembangan kulit rutin dan foto berkala pengguna.
  - Tabel `ingredients`: Database bahan aktif (misal: Salicylic Acid, Niacinamide, Ceramide, Centella Asiatica) beserta fungsi dan kecocokan jenis kulit.
  - Tabel `products`: Katalog produk skincare (nama produk, brand, kategori, harga, link pembelian/affiliate, list ingredients yang terkandung).
- [x] **2.2. Migrasi Database & Anti-Pause Automation**
  - Setup tool migrasi **Alembic** (Async engine SQLAlchemy + asyncpg) untuk version control skema database.
  - Menyediakan script manual SQL `schema.sql` untuk dijalankan langsung di Supabase SQL Editor.
  - Menyiapkan workflow otomatisasi GitHub Action `keep-supabase-alive.yml` untuk mencegah project Supabase dipause.

---

### Fase 3: Integrasi Model Machine Learning (Inference Pipeline)
*(Kolaborasi intensif dengan ML Engineer: Rafazl)*

- [ ] **3.1. Buat Service Wrapper Inferensi ML (`app/services/ml_service.py`)**
  - Mekanisme loading model (`.h5`, `.tflite`, atau `onnx`) saat startup server (bukan load ulang di setiap request agar hemat memori & cepat).
  - Preprocessing gambar masuk: validasi format (JPEG/PNG), ukuran file maks (misal 5MB), resize sesuai resolusi input model, dan normalisasi tensor.
  - Ekstraksi output prediksi model ke dalam metrik yang dimengerti oleh aplikasi:
    - *Skin type classification* (Normal, Berminyak, Kering, Kombinasi, Sensitif)
    - *Skin problem detection* (Acne, Pores, Redness, Oil level)
- [ ] **3.2. Buat Mock / Fallback Inference**
  - Sediakan fallback data simulasi (mirip logika `SkinDemoData`) jika model ML sedang dalam proses training atau belum siap dideploy, agar tim Mobile tidak terblokir.

---

### Fase 4: Engine Rekomendasi Skincare & Bahan Aktif
- [ ] **4.1. Logika Pemetaan Bahan Aktif (Ingredient Rule Engine)**
  - Tentukan aturan rekomendasi berdasarkan hasil scan:
    - Masalah Jerawat/Minyak tinggi $\rightarrow$ Rekomendasikan *Salicylic Acid*, *Tea Tree*, *Niacinamide*. Hindari minyak berat (*heavy comedogenic oils*).
    - Masalah Kemerahan/Skin barrier rusak $\rightarrow$ Rekomendasikan *Centella Asiatica*, *Ceramide*, *Hyaluronic Acid*. Hindari eksfoliasi keras.
- [ ] **4.2. Filter Katalog Skincare Berdasarkan Budget**
  - Buat query pencarian produk skincare berdasarkan:
    - Kecocokan bahan aktif yang disarankan
    - Filter rentang harga (*budget filter*: `< Rp 50.000`, `Rp 50.000 - Rp 150.000`, `> Rp 150.000`)

---

### Fase 5: Implementasi REST API Endpoints

#### A. Autentikasi & Profil Pengguna (`/api/v1/users`)
- `POST /api/v1/users/sync` : Sinkronisasi data user dari Supabase Auth ke database backend.
- `GET /api/v1/users/me` : Ambil profil pengguna beserta preferensi kulit.
- `PUT /api/v1/users/me` : Update data profil dan preferensi.

#### B. Kuis Gaya Hidup (`/api/v1/quiz`)
- `POST /api/v1/quiz/submit` : Simpan hasil kuis kondisi kulit awal pengguna.

#### C. Pemindaian & Analisis Kulit (`/api/v1/scan`) — *Endpoint Utama*
- `POST /api/v1/scan/analyze` :
  - Menerima file upload gambar wajah pengguna (`multipart/form-data`).
  - Mengunggah foto ke storage bucket (Supabase Storage / S3).
  - Menjalankan inferensi model ML.
  - Menghitung rekomendasi bahan aktif & produk.
  - Menyimpan ke `scan_records`.
  - Mengembalikan JSON hasil analisis lengkap (sesuai kontrak model `SkinAnalysis`).
- `GET /api/v1/scan/history` : Mengambil daftar riwayat scan pengguna (paginasi).
- `GET /api/v1/scan/history/{scan_id}` : Mengambil detail satu hasil scan.

#### D. Perjalanan Kulit / Journey (`/api/v1/journeys`)
- `GET /api/v1/journeys` : Ambil journey aktif pengguna.
- `POST /api/v1/journeys/checkin` : Simpan foto check-in progres kulit berkala.

#### E. Katalog Produk & Edukasi (`/api/v1/catalog` & `/api/v1/education`)
- `GET /api/v1/catalog/products` : Filter produk berdasarkan tipe kulit, bahan aktif, dan batas harga.
- `GET /api/v1/education/articles` : Mengambil artikel dan tips perawatan kulit harian.

---

### Fase 6: Penyimpanan Gambar (Cloud Storage)
- [ ] **6.1. Setup Bucket Penyimpanan Wajah**
  - Gunakan Supabase Storage atau AWS S3.
  - Buat bucket khusus untuk upload scan wajah dengan akses yang terkontrol (Private / Signed URL atau Protected Bucket).
  - Pastikan privasi data wajah terjaga (GDPR / penafian privasi data medis).

---

### Fase 7: Pengujian, Dokumentasi, & Deployment
- [ ] **7.1. Dokumentasi Swagger / OpenAPI**
  - Pastikan semua schema Request & Response di Pydantic memiliki deskripsi dan tipe data yang presisi.
  - Dokumentasi otomatis dapat diakses di `/docs` (Swagger UI) dan `/redoc`.
- [ ] **7.2. Automated Testing**
  - Unit test untuk business logic rekomendasi.
  - API integration test (upload test image dan pastikan format respons valid).
- [ ] **7.3. Deployment & CI/CD**
  - Buat `Dockerfile` yang ringan dan efisien.
  - Setup deployment ke cloud platform (misal: Railway, Render, Fly.io, atau VPS Kampus/Server PBL).
  - Bagikan base URL API kepada Bintang (Mobile Dev) untuk mulai integrasi HTTP client.

---

## 🤝 Koordinasi Antar Peran
| Rekan Tim | Hal yang Perlu Dikoordinasikan |
| :--- | :--- |
| **Bintang (Mobile Dev)** | Menyepakati kontrak JSON request/response endpoint `/scan/analyze` dan format error response. |
| **Rafazl (ML Engineer)** | Format file model yang diserahkan (`.h5`, `.tflite`, atau `onnx`), ukuran input citra, normalisasi nilai piksel, dan format tensor output. |
| **Adam (Project Manager)** | Melaporkan progres pengerjaan milestone backend mingguan sesuai jadwal PBL. |
