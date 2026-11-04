# SkinSight Backend Service

Modul backend untuk aplikasi **SkinSight**, bertanggung jawab sebagai orkestrator REST API, penghubung inferensi Machine Learning, manajemen database pengguna, serta rekomendasi produk & bahan aktif perawatan kulit.

## 📌 Dokumen Rencana Kerja & Tugas
Daftar seluruh tugas, fase pengembangan, dan spesifikasi endpoint dapat dilihat di:
👉 **[BACKEND_TASKS.md](./BACKEND_TASKS.md)**

## 🚀 Rencana Tech Stack
- **Framework:** FastAPI (Python 3.10+)
- **Database:** PostgreSQL (Supabase / Managed DB)
- **ORM / Migrations:** SQLAlchemy 2.0 & Alembic
- **Storage:** Supabase Storage / S3-compatible bucket
- **ML Runtime:** TensorFlow / ONNX Runtime / TFLite Runtime
- **Dokumentasi:** Swagger UI (`/docs`) & ReDoc (`/redoc`)
