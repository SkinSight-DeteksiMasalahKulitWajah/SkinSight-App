# SkinSight — feature-first monorepo

Repo ini disusun sebagai **satu monorepo** untuk aplikasi mobile, backend, ML, infrastruktur, dan pengujian. Folder backend/ML/infrastructure saat ini adalah kerangka kosong karena arsip yang diberikan hanya berisi `lib/` Flutter; tidak ada `pubspec.yaml`, implementasi backend, model ML, asset, atau konfigurasi deployment dalam arsip tersebut.

## Struktur utama

```text
SkinSight/
├── mobile/
│   └── lib/
│       ├── app/                 # bootstrap, komposisi aplikasi, splash screen
│       ├── core/                # aset dan konfigurasi lintas fitur
│       ├── features/            # kode dikelompokkan per fitur
│       │   ├── auth/
│       │   ├── scan/
│       │   ├── education/
│       │   ├── checkin/
│       │   ├── history/
│       │   ├── journeys/
│       │   ├── progress/
│       │   ├── notifications/
│       │   ├── profile/
│       │   └── ...
│       └── shared/              # komponen UI reusable antarfitur
├── backend/app/{api/routes,schemas,services}/
├── ml/
├── infrastructure/
├── tests/
├── .github/workflows/
├── RESTRUCTURE_MAP.json
└── README.md
```

## Peran tiap bagian

- `mobile/lib/features/<fitur>/presentation`: halaman dan widget khusus fitur.
- `mobile/lib/features/<fitur>/data`: akses data/repository/service khusus fitur.
- `mobile/lib/features/<fitur>/models`: model data yang dipakai fitur.
- `mobile/lib/features/<fitur>/domain`: aturan bisnis yang tidak seharusnya bergantung langsung pada UI.
- `mobile/lib/shared`: UI reusable yang tidak menjadi milik satu fitur.
- `mobile/lib/core`: hal lintas fitur seperti theme, konfigurasi, dan aset.
- `backend/app/api/routes`: HTTP endpoint. `schemas` untuk bentuk request/response. `services` untuk use case dan orkestrasi.
- `ml`: preprocessing, inferensi, serta konfigurasi model.
- `tests`: unit test dan test integrasi/kontrak antar komponen.

## Alur integrasi mobile ↔ backend

Backend tidak di-import langsung oleh Flutter. Mobile mengirim request HTTP ke endpoint backend; backend memvalidasi request, memanggil layanan inferensi di `ml`, lalu mengembalikan response sesuai kontrak API. Sebelum implementasi API client dipasang ke UI, tetapkan kontrak request/response (idealnya OpenAPI) dan base URL per environment. Arsip asal belum memuat endpoint atau kontrak tersebut, jadi API client belum dibuat agar tidak mengarang bentuk response dan tidak menampilkan data demo seolah-olah hasil model asli.

## Clean Code: aturan yang dipakai

Clean Code bukan checklist yang harus dipaksakan secara literal. Target utamanya: developer lain bisa memahami, mengubah, dan menguji kode dengan risiko rendah.

1. **Konvensi konsisten** — nama file/class/variabel mengikuti konvensi Dart; format dijalankan lewat `dart format`.
2. **KISS, cari akar masalah, Boy Scout Rule** — hindari abstraksi yang belum dibutuhkan, perbaiki penyebab bukan gejala, dan jangan menyisakan kode mati.
3. **Konfigurasi di batas aplikasi** — URL API, kunci, dan environment masuk lewat konfigurasi; rahasia tidak ditanam di source.
4. **Satu tanggung jawab per modul/fungsi** — UI mengurus presentasi/interaksi, repository mengurus akses data, service/use case mengurus alur bisnis.
5. **Nama jelas dan bisa dicari** — hindari nama kabur serta angka literal yang tidak menjelaskan maksud.
6. **Fungsi ringkas dan fokus** — pecah fungsi bila beberapa langkah punya alasan perubahan yang berbeda; jumlah baris bukan tujuan tunggal.
7. **Hindari flag argument bila membuat perilaku bercabang** — gunakan API atau fungsi berbeda bila dua jalur benar-benar punya makna berbeda.
8. **Dependency Injection secara proporsional** — injeksikan dependensi yang perlu diganti saat test/environment; jangan membuat container/framework berlebihan.
9. **Jaga batas dependensi** — UI boleh memanggil controller/use case/repository melalui API yang jelas; fitur tidak saling mengakses detail internal secara sembarangan.
10. **Komentar untuk alasan, bukan mengulang kode** — dokumentasikan alasan atau konsekuensi yang tak jelas dari implementasi.
11. **Tes deterministik dan independen** — tes satu perilaku penting per test, cepat, dapat diulang, dan tidak bergantung pada urutan test.
12. **Pantau code smells** — coupling tinggi, satu perubahan memaksa banyak file berubah, logika duplikat, fungsi terlalu panjang, dan file yang menyimpan terlalu banyak alasan perubahan.

### Catatan atas aturan yang sering disalahartikan

- **“One assert per test” bukan hukum mutlak.** Satu test boleh punya beberapa assertion jika semuanya memverifikasi satu hasil/perilaku yang sama. Yang penting test punya satu alasan untuk gagal.
- **“Prefer polymorphism to if/else” bukan berarti semua `if` harus dihapus.** Gunakan polymorphism ketika ada variasi perilaku yang stabil; conditional sederhana justru lebih terbaca.
- **“No side effects” tidak berarti aplikasi tak boleh mengubah state.** Maksudnya, fungsi sebaiknya tidak menyembunyikan efek samping di balik nama yang tampak seperti perhitungan murni.
- **“Small functions” bukan batas jumlah baris.** Pecah fungsi berdasarkan tanggung jawab dan tingkat abstraksi, bukan sekadar memotongnya menjadi banyak fungsi kecil.
- **Value object/polymorphism/DI dipakai saat menambah kejelasan atau testability, bukan demi memenuhi daftar.** Abstraksi yang tidak memberi manfaat adalah needless complexity.

## Yang sudah diubah dalam tahap ini

- Memindahkan 67 file Dart dari `pages/`, `data/`, `models/`, `theme/`, dan `widgets/` menjadi struktur feature-first.
- Menghitung ulang seluruh import relatif yang menunjuk file Dart di dalam arsip.
- Memisahkan `main.dart` menjadi entry point, bootstrap, konfigurasi komposisi aplikasi, dan splash screen.
- Mempertahankan nama halaman dan rute lama agar referensi yang sudah ada tidak berubah karena refactor struktur.
- Menaruh timeline engine/policy di domain fitur progress; komponen UI lintas fitur di `shared`; theme dan aset di `core`.

## Batasan verifikasi

Zip asal hanya berisi `lib/`; `pubspec.yaml`, asset, konfigurasi platform, dan test tidak tersedia. Karena itu project ini belum dapat diverifikasi dengan `flutter analyze` atau dijalankan sebagai aplikasi utuh hanya dari arsip ini. Sebelum memakai struktur hasil ini, gabungkan `mobile/lib` dengan project Flutter asli beserta `pubspec.yaml`, `assets/`, `android/`, `ios/`, dan konfigurasi lainnya, lalu jalankan format, analyzer, dan test.
"# SkinSight-App" 
