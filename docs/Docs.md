# Docs

Tahap ini memprioritaskan **struktur modul dan batas tanggung jawab** tanpa mengganti alur UI aplikasi secara mekanis. Pindah folder bukan bukti bahwa setiap fungsi sudah clean; file besar berikut masih perlu refactor internal bertahap setelah project Flutter lengkap bisa dianalisis dan dijalankan.

## Prioritas tinjauan

Urutan berdasarkan panjang file, bukan otomatis berarti kode di dalamnya salah:

- `mobile/lib/shared/widgets/design_system/skin_ui.dart` — 1730 baris
- `mobile/lib/features/progress/presentation/skin_progress_page.dart` — 1329 baris
- `mobile/lib/features/home/presentation/skin_home_page.dart` — 1185 baris
- `mobile/lib/features/scan/presentation/skin_scan_page.dart` — 883 baris
- `mobile/lib/features/scan/presentation/skin_initial_scan_page.dart` — 777 baris
- `mobile/lib/features/journeys/data/skin_journey_store.dart` — 730 baris
- `mobile/lib/features/journeys/presentation/skin_journeys_page.dart` — 720 baris
- `mobile/lib/features/auth/presentation/skin_login_page.dart` — 713 baris
- `mobile/lib/features/profile/presentation/skin_profile_page.dart` — 704 baris
- `mobile/lib/features/scan/presentation/skin_result_page.dart` — 682 baris
- `mobile/lib/features/support/presentation/skin_help_page.dart` — 678 baris
- `mobile/lib/core/theme/skin_theme.dart` — 613 baris
- `mobile/lib/features/about/presentation/skin_about_page.dart` — 580 baris
- `mobile/lib/features/scan/presentation/skin_quiz_page.dart` — 563 baris
- `mobile/lib/features/education/presentation/skin_education_page.dart` — 548 baris
- `mobile/lib/features/profile/presentation/skin_account_page.dart` — 534 baris
- `mobile/lib/shared/widgets/skin_showcase.dart` — 514 baris
- `mobile/lib/features/progress/domain/skin_timeline_engine.dart` — 473 baris
- `mobile/lib/features/legal/presentation/skin_legal_pages.dart` — 405 baris
- `mobile/lib/features/education/presentation/widgets/skin_article_widgets.dart` — 402 baris

## Cara refactor file besar dengan aman

1. Tulis/pertahankan test untuk perilaku sekarang terlebih dahulu, khususnya alur foto, hasil scan, penyimpanan journey, dan navigasi.
2. Pisahkan widget privat berdasarkan tanggung jawab tampilan. Jika perlu dipakai lintas file, ubah jadi API publik yang spesifik; jangan membuka semua detail internal.
3. Pindahkan state dan aturan bisnis dari `State` widget ke controller/use case hanya jika batasnya nyata dan bisa diuji. Jangan menambah controller kosong sekadar mengikuti template.
4. Pisahkan data demo dari implementasi inferensi server. Di kode saat ini, `SkinDemoData.forPhoto(...)` masih dipakai untuk menghasilkan hasil ilustratif; itu **bukan** panggilan ke backend atau model ML.
5. Setelah setiap perubahan kecil, jalankan `dart format`, `flutter analyze`, dan test pada project Flutter lengkap sebelum melanjutkan.

## Yang belum bisa diverifikasi dari arsip sumber

Arsip hanya berisi `lib/`. `pubspec.yaml`, assets, platform folders, endpoint backend, dan model ML tidak disertakan. Karena itu tidak aman untuk mengarang `scan_api_client.dart` dengan request/response buatan atau mengklaim aplikasi sudah terintegrasi ke backend. Setelah kontrak API disepakati, lapisan client bisa ditambahkan di `mobile/lib/features/scan/data/` dan diuji terhadap kontrak tersebut.
