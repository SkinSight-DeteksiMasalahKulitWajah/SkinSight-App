# SkinSight 🔍✨

> **Aplikasi Deteksi Kondisi Kulit Tubuh Berbasis Machine Learning**

SkinSight adalah aplikasi mobile cerdas yang membantu pengguna mengidentifikasi kondisi kulit wajah secara presisi. Dengan menggabungkan teknologi pemindaian citra kulit berbasis Machine Learning dan analisis gaya hidup pengguna, SkinSight memberikan rekomendasi bahan aktif (ingredients), produk skincare terkurasi, serta edukasi pola makan yang dipersonalisasi.

---

## 👥 Tim Pengembang (Kelompok 2 - PBL Semester 5, 2026)
Proyek ini dikembangkan oleh mahasiswa Program Studi Teknik Informatika, Politeknik Negeri Malang:

| Nama | NIM | Peran |
| :--- | :--- | :--- |
| **Moch. Adam Arsyad F.** | 244107020104 | Project Manager |
| **Bintang Pancahaya P.** | 244107020115 | Mobile Developer |
| **Rafazl Radana D.** | 244107020082 | ML Engineer |
| **Muchammad Ibrahim A. A** | 244107020062 | UI/UX Designer |
| **Anthea Amodia Syaffah A.**| 244107020024 | QA / Dokumentasi |

**Dosen Pembimbing:**
* Titis Octary Satrio, S.ST., M.MT. (Penjaminan Mutu Perangkat Lunak)
* Muhammad Afif Hendrawan, S.Kom., M.T. (Pembelajaran Mesin)
* Agung Nugroho Pramudhita, S.T., M.T. (Pemrograman Mobile)

---

## ✨ Fitur Utama
- **📝 Kuis Kondisi Kulit & Gaya Hidup**: Pengumpulan data awal (alergi, pola makan, kebiasaan) sebelum pemindaian.
- **📸 Smart Skin Scan**: Pemindaian area kulit (wajah, tangan, punggung, kaki) langsung menggunakan kamera smartphone.
- **🧠 Analisis Machine Learning**: Deteksi kondisi/masalah kulit dengan akurasi tinggi menggunakan model.
- **🧪 Rekomendasi Ingredients**: Saran bahan aktif perawatan kulit yang aman dan sesuai dengan hasil analisis.
- **🛍️ Katalog Skincare (Filter Harga)**: Rekomendasi produk riil di pasaran yang bisa disaring berdasarkan *budget* pengguna.
- **🥗 Edukasi & Pola Hidup**: Tips harian dan saran nutrisi untuk perawatan kulit secara holistik.

---

## 🛠️ Teknologi yang Digunakan
* **Frontend / Mobile App:** [Flutter](https://flutter.dev/) (Dart)
* **Machine Learning:** Python, TensorFlow / Keras (Model arsitektur CNN)
* **Dataset:**
  * [Skin Disease Dataset](https://www.kaggle.com/datasets/pacificrm/skindiseasedataset) (Kaggle)
  * Indonesian Skincare Dataset (Female Daily)

---

## 🚀 Cara Menjalankan Proyek Secara Lokal

### Prasyarat
Sebelum memulai, pastikan perangkat Anda telah terinstal perangkat lunak berikut:
1. [Flutter SDK](https://docs.flutter.dev/get-started/install) (Versi terbaru)
2. [Android Studio](https://developer.android.com/studio) atau [VS Code](https://code.visualstudio.com/) dengan ekstensi Flutter & Dart.
3. Emulator Android / iOS, atau perangkat fisik.
4. Python 3.x (Untuk melatih atau menjalankan *server* model ML, opsional jika API sudah di-*deploy*).

### Instalasi Aplikasi Mobile (Flutter)
1. **Clone repositori ini**
   ```bash
   git clone https://github.com/username-organisasi/skinsight.git
   cd skinsight/mobile
   ```
2. **Unduh dependensi (packages)**
   ```bash
   flutter pub get
   ```
3. **Jalankan aplikasi**
   ```bash
   flutter run
   ```

### Menjalankan / Melatih Model Machine Learning
*(Catatan: Instruksi ini berjalan di direktori `/machine_learning`)*
1. Navigasi ke folder ML: `cd machine_learning`
2. Buat Virtual Environment (disarankan): `python -m venv venv` dan aktifkan.
3. Instal dependensi: `pip install -r requirements.txt`
4. Jalankan skrip *training*: `python train_model.py` atau jalankan API lokal: `python app.py`

---

## 📁 Struktur Folder Utama
```text
skinsight/
│
├── mobile/                   # Source code aplikasi Flutter (Frontend)
│   ├── lib/                  # Kode utama Dart (UI, Logic, API integration)
│   ├── assets/               # Gambar, ikon, dan font
│   └── pubspec.yaml          # Konfigurasi dependensi Flutter
│
├── machine_learning/         # Script pengolahan data & model ML
│   ├── datasets/             # Folder penyimpan dataset gambar mentah
│   ├── notebooks/            # Jupyter Notebooks untuk riset & eksperimen
│   ├── models/               # File model CNN yang telah dilatih (.h5 / .tflite)
│   └── api/                  # Script Flask/FastAPI untuk melayani prediksi model
│
├── docs/                     # Dokumentasi PBL, Proposal, Laporan Pengujian
└── README.md                 # Dokumentasi repositori ini
```

---

## ⚠️ Batasan dan Penafian (Disclaimer)
Aplikasi **SkinSight** dirancang murni sebagai alat bantu edukasi dan rekomendasi awal. Analisis yang dihasilkan **bukan** merupakan diagnosis medis, resep klinis, atau pengganti dari anjuran dokter spesialis kulit (Dermatolog). Segala bentuk risiko iritasi atau masalah kulit lanjutan akibat penggunaan produk tetap menjadi tanggung jawab pengguna.

---

## 📄 Lisensi
Proyek ini dikembangkan dalam rangka *Project Based Learning (PBL)* Politeknik Negeri Malang Tahun 2026. Semua hak cipta atas laporan dan kode sumber mengikuti kebijakan institusi terkait.

---

## 🎨 Aset UI

Aset antarmuka yang tersedia meliputi `skin_girl.png`, `skin_magnifier.png`,
`skin_analyze_title.png`, `cat_happy.png`, `city_background.png`, `clouds.png`,
`bubbles.png`, `leaves_flowers.png`, `sparkles.png`, `hero_decor.png`,
`try_now_sticker.png`, dan `description_sticker.png`.

Halaman Flutter menggunakan kanvas desain 941×1672 dan menskalakan komposisi
secara proporsional.
