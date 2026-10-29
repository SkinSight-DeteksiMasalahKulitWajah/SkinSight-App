# Ledger — Migrasi SkinSight v2.0

Catatan eksekusi `2026-10-17-skinsight-v2-full-migration.md`. **TANPA COMMIT** (permintaan pengguna); semua perubahan di working tree.

Status: `[ ]` belum · `[~]` sedang · `[x]` selesai + terverifikasi

## Tahap 1 — Tema & Font
- [x] Task 1 — Bundel font + wiring tema + `theme_font_test`
- [x] Task 2 — Token bersih + `token_contrast_test`

## Tahap 2 — Data & Parser
- [x] Task 3 — Parser tahan-rusak + perluasan test kontrak
- [x] Task 4 — Mock → string JSON + seam & state `SkinAnalysisPage`

## Tahap 3 — Komponen + Layar Fungsional
- [x] Task 5 — `lib/widgets/` 9 komponen + smoke test
- [x] Task 6 — Result migrasi + polish (+ hapus route `/result`)
- [x] Task 7 — Quiz migrasi + kembali antar-soal + eyebrow
- [x] Task 8 — Scan migrasi (token-only)
- [x] Task 9 — Menyusun (Analysis) body migrasi

## Tahap 4 — Beranda → Data → Riwayat
- [x] Task 10 — Beranda redesain + pecah file
- [x] Task 11 — Data layer v2.0 + Riwayat redesain
- [x] Task 12 — Uji alur Quiz → Analysis → Result → Riwayat

## Tahap 5 — Zona Hangat
- [x] Task 13 — Start
- [x] Task 14 — Masuk (+ baris usia)
- [x] Task 15 — Bantuan (+ Versi 2.0.0)
- [x] Task 16 — Profil (+ badge Demo)

## Tahap 6 — Bersih-bersih & DoD
- [x] Task 17 — Hapus alias legacy/kode mati/aset + sweep DoD

## Catatan
- Verifikasi tiap task: `flutter analyze` bersih + test terkait hijau; akhir tahap: suite penuh.
- Deviasi: penyederhanaan data dipindah ke Task 11 (lihat catatan di rencana).
- Mesin ini OOM bila suite paralel → jalankan suite penuh dengan `flutter test --concurrency=1`.
- Task 11 (dilanjutkan di sesi berikutnya): implementasi & test sudah ada di working tree, tetapi test Riwayat masih merah — akar masalah di test (jam fake berhenti di 100 ms < latensi mock 160 ms saat `pumpAndSettle`), bukan produksi. Ruling: tambah `pump` eksplisit di test (pumpHistory, sort, delete). Bukti: 9/9 file Riwayat hijau, 25/25 (riwayat+dashboard+result) hijau.
- Task 12: test alur gagal pada leg Analysis karena `MaterialApp` leg berikutnya di-reuse (tipe elemen sama) sementara route `/` sudah digantikan `pushReplacement` di leg quiz → home baru tak pernah terpasang. Ruling: beri `key: UniqueKey()` pada MaterialApp leg Analysis & Riwayat di test agar navigator segar.
- Task 15: `ExpansionTile` memakai `ListTile` internal; `SectionCard` (`Container` berdekorasi) memicu assertion debug "ListTile background color or ink splashes may be invisible". Ruling: bungkus `ExpansionTile` dengan `Material(type: MaterialType.transparency)` di dalam `_HelpTopic`, bukan ubah `SectionCard` bersama. Bukti: 4/4 `help_page_test` hijau, `Color(0x` nol di halaman, analyze bersih.
- Task 13–15 bukti: Task 13 6/6 `start_page_test` (termasuk FR-01 360×640); Task 14 6/6 `login_page_test` + grep `Color(0x` = hanya mark Google; Task 15 di atas.
- Task 16: header memakai `ScreenHeader` (tombol kembali = tooltip 'Kembali'; test tombol kembali diperbarui). Kartu field memakai `SectionCard(padding: zero)`. Dua `const Text(... AppTokens.h2/caption)` dilepas `const`-nya (pola getter token vs const eval). Bukti: 5/5 `profile_page_test` hijau, `Color(0x`/`Colors.` nol di file, analyze bersih.
- Tahap 5 selesai: suite penuh 82 test hijau (`flutter test --concurrency=1`), `flutter analyze` bersih.
- Task 17: alias legacy dihapus dari `app_tokens.dart` (grep `AppTokens\.(teal|deepTeal|navy|cream|pageBg|cardBorder|muted|coral|orange|sky)` = nol di `lib/`+`test/`; sisa hanya di `PRD_SkinSight.md` lama yang tidak disentuh). `flutter_animate` dihapus dari pubspec (nol import; `flutter pub get` sukses). 11 aset dihapus setelah grep nol referensi; `skin_girl.png` + `skin_magnifier.png` TIDAK dihapus (di luar daftar rencana) walau tanpa referensi kode — kandidat bersih-bersih lanjutan untuk tim. Token baru `AppTokens.transparent` (pengganti `Colors.transparent` di help page). `TextStyle(` halaman/widget dikonversi ke role `.copyWith` (start/login brand mark, "Segera hadir", toggle Masuk/Daftar, mark Google, nomor langkah help, label logout profil, `step_list`).
- Task 17 sweep bukti: `Color(0x` di `lib/` = 13 di `app_tokens.dart` + 1 pengecualian mark Google (`skin_login_page.dart:408`); `Colors.` = hanya `app_tokens.dart`; `TextStyle(` = hanya `lib/theme/`; string "1.1" versi tidak ada (grep `1\.1` hanya angka `1.12`/`1.15`); analyze bersih; suite penuh 82 hijau.

## DoD §15 (bukti)
1. **360×640 tanpa overflow** — `start_page_test` (FR-01, 360×640); `scan_result_responsive_test` (360×640 @ textScale 1.3); scan/result 320/390/412; home 320/375/390/430; start/login/help/profile 320/390. ✓
2. **Tanpa warna hardcode** — sweep di atas (hanya tokens + pengecualian Google terdokumentasi). ✓
3. **Font Plus Jakarta Sans** — `theme_font_test` (textTheme family, 4 TTF terbundel, pewarisan). ✓
4. **Result 3 panjang + 1 rusak** — `recommendation_contract_test` (normal/panjang/rusak + salvage), `analysis_page_test` (sukses/timeout/retry-3/decode gagal), `flow_quiz_to_history_test` (skenario `pendek`). ✓
5. **Kontras §10.3** — `token_contrast_test` (rasio WCAG pasangan kunci + dokumentasi `primarySoft` gagal-untuk-teks-kecil). ✓
6. **Disclaimer & consent** — disclaimer: `_DisclaimerCard` (`Key('disclaimer')`, `AppCopy.disclaimer`) + diuji; consent: dialog `AppCopy.consentTitle/Body/Agree` di `skin_scan_page.dart` — alur kamera tak dapat dikemudikan di widget test → **smoke manual** (tercatat Task 12). ✓ tertunda manual
7. **Label Indonesia (glosarium §9.5)** — copy terpusat `AppCopy` + asersi test (nav 4 label, CTA "Mulai scan", dsb). ✓
8. **Dokumen disetujui dosen** — **manual, di luar kode**. ⏳
- Catatan: `skinsight-figma.html` sudah termodifikasi di working tree (368+/175−, termasuk `d<!DOCTYPE` di baris 1) SEBELUM/DI LUAR migrasi ini — kemungkinan pekerjaan pengguna (referensi v2: `--teal2`/`--deep2`). Tim perlu meninjau `d` nyasar itu. File tidak disentuh oleh migrasi.

## Review Akhir (subagent, read-only) & Perbaikan
Verdict awal: "Ready to merge — conditional on I-1 & I-2".
- **I-1** (Beranda berkedip empty state saat muat pertama) → fix: skeleton `_LatestCardSkeleton` di `skin_home_page.dart` (pola `_HistorySkeleton`; `waiting && !hasData` agar tanpa flicker saat reload). Test baru `dashboard_history_test`: "Beranda saat muat pertama: skeleton, bukan empty state" — RED→GREEN terbukti.
- **I-2** (kepala FAB BottomNav menjulang keluar Stack → tidak dapat di-tap; target efektif <48px) → fix: bilah diberi ruang `fabOverhang = 22` + `Positioned(top: 0)` di `sight_bottom_nav.dart`. Test baru `widgets_smoke_test`: tap di tepi atas FAB membuka quiz — RED→GREEN terbukti.
- **I-3 sebagian**: + 5 test 360×640 (loop login/help/profile/history/home) dan + test tab-jump BottomNav (Profil→Beranda). Sisa tercatat: cabang error `FutureBuilder` Beranda/Riwayat butuh seam repo; textScale 1.3 di luar Result.
- **Minor dari reviewer (dicatat untuk tim, tidak menggigit DoD):** aset mati `skin_girl.png`/`skin_magnifier.png` (M-1); konstanta `AppCopy` duplikat/daksi (`ctaPilihGaleri`, `ctaBukaPengaturan`, `soonBadge`, literal 'Segera hadir'/'Pilih dari galeri') (M-2); `StatusTone.error` mati (M-3); token `AppLayout` quiz tak terpakai (M-4); kontras angka langkah Bantuan di `primarySoft` ≈4.25:1 (M-5); "Selengkapnya" >140 char vs >3 baris (M-6); indikator jawaban quiz radio vs ikon centang (M-7); key `history-preview-row` duplikat di test (M-8); singleton repo antar-test non-hermetik (M-9); string `ScreenHeader`/`ErrorState` di luar `AppCopy` (M-10); `semanticLabel` `_SquareAction` (M-11); `_dateOnly` tanpa tahun (M-12).
- **Pasca-review final: suite penuh 90 hijau (`flutter test --concurrency=1`), `flutter analyze` bersih.**
- Tahap 4 selesai: suite penuh 78 test hijau (`flutter test --concurrency=1`), `flutter analyze` bersih.
