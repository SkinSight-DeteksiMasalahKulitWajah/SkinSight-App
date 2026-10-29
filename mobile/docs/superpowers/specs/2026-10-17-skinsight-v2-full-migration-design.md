# SkinSight v2.0 — Desain Migrasi Penuh "Calm Clinical"

**Tanggal:** 17 Oktober 2026 · **Status:** Disetujui 17 Okt 2026 — scope penuh, **tanpa commit** (semua perubahan ditinggal di working tree) · **Acuan:** `PRD SkinSight v2.0.md` (§1–§19)
**Scope sesi:** seluruh sisa PRD v2.0 di codebase ini, hingga lolos Definition of Done §15.

---

## 1. Konteks

Repo `PBL-Kel2-SkinSight-adam` sudah "setengah jalan" ke v2.0:

- **Sudah v2.0:** `lib/theme/app_tokens.dart` (token §10 lengkap + alias legacy), `app_theme.dart` (M3, wiring token), `app_layout.dart`, `app_copy.dart`, `models/skin_recommendation.dart` (kontrak §8 + parser defensif), `data/mock_recommendation_repository.dart` (5 skenario), `pages/skin_result_page.dart` (struktur §9.3), `skin_analysis_page.dart` (skeleton + error), Quiz & Scan (consent, 10 MB, galeri), 12 file test.
- **Masih v1.1 / belum sesuai PRD:** Beranda (kartu skor `/100`, metrik bar, grafik batang), Riwayat (badge skor), Start/Masuk/Bantuan/Profil (warna hardcode + gradien lama), font masih `google_fonts` runtime, **125 `Color(0x…)` hardcode & 91 `TextStyle` inline** di file halaman, komponen duplikat (header back 5×, bottom-nav 3×), parser punya celah, dan kode mati (`scoreQuiz`, `saveLatest`, route `/result`, dep `flutter_animate`).

Dokumen ini menetapkan keputusan teknis, peta migrasi, spesifikasi per layar, rencana bertahap, dan kriteria selesai.

---

## 2. Tujuan & Non-tujuan

**Tujuan**
1. Satu sumber token: semua warna/teks/radius/shadow hanya dari `lib/theme/` (DoD §15: "tidak ada warna hardcode di luar token §10").
2. Font Plus Jakarta Sans **dibundel sebagai asset** (bukan unduhan runtime, §10.4) dan terpasang konsisten.
3. Beranda & Riwayat berhenti menampilkan skor lama → berpusat pada **rekomendasi** (§1, §9.3, kontrak §8 tanpa skor).
4. Parser tahan JSON rusak/tidak lengkap → **0 layar kosong** (§3.3, §8.4, FR-14), jalur `jsonDecode` nyata teruji.
5. Komponen bersama di `lib/widgets/`; duplikasi header/bottom-nav dihapus; Beranda dipecah menjadi widget kecil (§12).
6. Kode mati & label versi lama dibersihkan; `flutter analyze` + `flutter test` hijau; responsif 320–600+ tanpa overflow.

**Non-tujuan (PRD §3.2 + batasan sesi)**
- Integrasi model AI nyata, backend, atau persistensi disk (tetap mock in-memory, Fase A).
- Dark mode, multi-bahasa, e-commerce, pelacakan progres foto.
- Menyentuh `skinsight-figma.html` (ada perubahan belum di-commit milik pengguna).
- Kompresi aset gambar resolusi 2×/3× (butuh tool grafis; dicatat sebagai backlog §12).

---

## 3. Keputusan teknis

Tanda ⚑ = poin yang dikonfirmasi pengguna. **Status 17 Okt 2026: semua terkonfirmasi** — skor dimatikan total, `scoreQuiz` dihapus, pernyataan usia ≥17 ditampilkan (§10).

**D1 — Token satu pintu.**
`app_tokens.dart` tetap satu-satunya sumber. Alias legacy (`teal`, `deepTeal`, `navy`, `cream`, `pageBg`, `cardBorder`, `muted`, `coral`, `orange`, `sky`) dihapus **di tahap akhir**, setelah semua pemakai dimigrasi. Gradient/shadow non-token dibersihkan:
- `primaryGradient` & `primarySoftGradient` (hex di luar §10.2) → dihapus. CTA utama jadi **flat `primary`**; header zona hangat memakai gradien berbasis token (`surfaceWarm`/`successSoft` → `bg`), maks 25% tinggi layar (§10.1).
- `buttonShadow` (α .28) → dihapus (gaya tenang §9.1).
- `cardShadowSoft` (α .07) → dihapus. Satu-satunya bayangan kartu = `card()` (§10.5: primary 6%, blur 12, offset (0,4)); **dimatikan di atas latar gradien**.
- Aturan akhir: literal `Color(0x…)` hanya boleh ada di `lib/theme/app_tokens.dart`. Pengecualian terdokumentasi: logo Google di tombol "Masuk dengan Google" (brand pihak ketiga) dan warna dalam aset gambar.

**D2 — Font dibundel.**
Unduh static TTF Plus Jakarta Sans (400, 600, 700, 800) dari distribusi resmi (lisensi OFL) → `assets/fonts/`, daftarkan blok `fonts:` di `pubspec.yaml`; set `ThemeData(fontFamily: 'Plus Jakarta Sans')`; hapus dependensi `google_fonts`. Perbaikan ikutan: `labelLarge` mentah tanpa family di `app_theme.dart:30–34` ikut ter-family-kan.
Bila unduhan jaringan gagal di mesin ini, tim menyediakan file TTF-nya; struktur pemasangan sama.
Verifikasi DoD "font tidak jatuh ke bawaan": widget test membaca `Theme.of(context).textTheme.bodyMedium.fontFamily`.

**D3 — Beranda tanpa skor.**
Kontrak §8 tidak memuat skor. Yang dihapus dari Beranda: kartu skor `/100`, badge kondisi kulit berbasis ambang skor, 3 metrik bar (Kemerahan/Minyak/Hidrasi), grafik batang skor, dan **semua angka fallback palsu** (82/68/34/78, deret `[35,47,…]`). Penggantinya: kartu **hasil terakhir** (tipe kulit + tanggal + tombol "Lihat hasil" → Result mode baca), preview riwayat terbaru, dan CTA "Mulai scan". Tanpa data → empty state jujur (ikon + 1 kalimat + CTA).

**D4 — Riwayat tanpa skor.**
Baris riwayat = tipe kulit + tanggal/jam + status ("Rekomendasi tersimpan"); badge skor dan teks "Minyak x% · Kemerahan y%" dihapus. Data seed repository (3 record skor) diganti 3 record rekomendasi v2.0 (skenario normal/pendek/panjang) supaya demo konsisten.

**D5 — Hapus kode mati.**
- `lib/data/quiz_scoring.dart` + `test/quiz_scoring_test.dart` (skor quiz lama; §17 no.2 → dihapus).
- `SkinHistoryRepository.saveLatest` (tak dipakai).
- Route `'/result'` di `main.dart` (tak pernah dinavigasi; bila diakses menghasilkan layar kosong).
- Dependensi `flutter_animate` (tanpa import).
- `SkinAnalysis` disederhanakan menjadi pembungkus riwayat: `id`, `analyzedAt`, `recommendation`, `selfieBytes` — field skor/tipe/metrik legacy dibuang karena semua pemakainya (UI skor) ikut dihapus.

**D6 — Parser diperketat + jalur JSON nyata.**
- Mock repository mengembalikan **string JSON** (bukan Map Dart) → `jsonDecode` dipakai sungguhan; dipisah: decode (bisa gagal → error state) vs mapping (tidak pernah melempar untuk field non-fatal).
- Helper tipe aman (`_asString`, `_asList`, `_asMap`) → tidak ada `TypeError` untuk field bertipe salah.
- `tipe_kulit` kosong/bukan string → tampil **"Belum dapat ditentukan"** + notice "scan ulang" (§8.4 no.3), **bukan** error screen. `FormatException` hanya bila JSON total tak terbaca/bukan objek.
- Salvage per-item: satu zat aktif/referensi rusak → buang item itu saja, bukan seluruh daftar.
- `_clipSteps(min:)` dihapus (parameter tak pernah dipakai).
- `FutureBuilder` di Riwayat & Beranda mendapat cabang error (pesan + "Coba lagi") — tidak lagi menyamar sebagai "kosong".

**D7 — Komponen bersama `lib/widgets/`.**
`ScreenHeader` (tombol kembali bulat), `SightBottomNav` (4 tujuan + FAB tengah "Mulai scan"), `SectionCard`, `StepList` (langkah bernomor), `AvoidChip` (ikon + teks), `DemoBadge`, `EmptyState`, `ErrorState`, `StatusNotice`. Layar memakai komponen ini; salinan privat dihapus. Menggantikan pola: header back (help/history/profile/scan/result), bottom-nav (home/history/help).

**D8 — Navigasi & bottom nav.**
Pertahankan Navigator 1.0 + named route yang ada. BottomNav mengikuti §9.5: **Beranda · Riwayat · [Mulai scan] · Bantuan · Profil** (ikon 24 dp + label selalu tampil), tampil di 4 layar tab, **disembunyikan di Result** (dan tidak ada di Quiz/Scan/Analysis). Tombol nav "quiz" lama di Riwayat/Bantuan diganti aksi "Mulai scan" via FAB.

**D9 — Referensi.**
Tetap opsi label (§8.3b): "Rujukan umum, belum diverifikasi" (mock sudah memakai). Daftar putih = pekerjaan kurasi konten, bukan kode.

**D10 — Zona visual (§9.2) ditegakkan.**
Hangat = Start, Masuk, Beranda, Bantuan: gradien pastel lembut **berbasis token**, maks 25% tinggi layar, lantas memudar ke `bg`; maks 1 ilustrasi hero. Fungsional = Quiz, Scan, Result, Riwayat, Profil: latar netral `bg`, **tanpa** painter blob/circle dekoratif. Gradien sky-blue lama (`#2FC1ED` dkk.) dan semua painter dekoratif di zona fungsional dihapus.

**D11 — Alur kerja (revisi 17 Okt: tanpa commit).**
Semua perubahan ditinggal di working tree branch `ibra` — **tanpa commit apa pun** (permintaan pengguna). Tiap tahap tetap diverifikasi: `flutter analyze` bersih, `flutter test` hijau, grep-audit (jumlah `Color(0x` di luar `lib/theme/` menuju 0; jumlah `TextStyle(` inline di luar `lib/theme/` menuju 0), plus laporan singkat. Pengguna yang akan commit sendiri.

**D12 — Responsif & aksesibilitas.**
Pola `AppLayout`/`scaleFor` dipertahankan (§11). Tambahan: `semanticLabel` pada ikon bermakna, chip memakai `Wrap` + ikon+t teks (bukan warna saja), animasi menghormati *reduce motion* (`MediaQuery.disableAnimations`), target sentuh ≥48, uji kontras token sebagai "bukti alat uji" (test terpisah, §7).

---

## 4. Peta migrasi warna legacy → token

Aturan umum: maksud pemakaian yang menentukan token, bukan kemiripan hue. Tabel nilai yang paling sering (census lengkap di lampiran).

| Nilai legacy (contoh pemakai terbanyak) | Ganti dengan | Catatan |
|---|---|---|
| `#6C7F8D`, `#6A7F8B`, `#718392`, `#5B737C`, `#71838B`, `#718184`, `#6F8085`, `#73898B`, `#7B8B95`, `#8A9BA5`, `#829194`, `#819093`, `#78878A`, `#6D808A`, `#526E78` | `inkSecondary` | teks sekunder/caption (menggantikan `#6B7E89` lama) |
| `#064E48`, `#142D35`, `#087B6B`, `#087B6D`, `#169481` | `primary` (teks/CTA) / `primarySoft` (ikon/ilustrasi) | peran menentukan |
| `#168F7C`, `#1BA18E`, `#2BB79B`, `#0A8A74`, `#06655A`, `#47C2AC`, `#5FC7AE`, `#7AD5B7`, `#79D7B6`, `#55C69E` | `primarySoft` | hanya grafis/ikon, bukan teks kecil |
| `#2FC1ED`, `#36A7E8`, `#2DA6F2`, `#67BEEA`, `#47BDE8` | `info` atau dihapus | hanya grafis; dekoratif di zona fungsional → hapus |
| `#4285F4` (+ sakel) | tetap di dalam `_GoogleMark` | brand Google, pengecualian terdokumentasi |
| `#E3F4F0`, `#E6F7F3`, `#E2F4EF`, `#E6F4EF`, `#E1F5EF`, `#E3F6F0`, `#E1F7F5`, `#E9F7F4`, `#E8FBF7`, `#E9F8F3` | `successSoft` | latar terpilih/badge sukses |
| `#F4FAF8`, `#F1F2F2`, `#F6F8F7`, `#F4F6F6` | `bg` | latar netral |
| `#E8ECEC`, `#E7ECEC`, `#E4E8E7`, `#E0E7E5`, `#E5EBEA`, `#E4EAEF`, `#E3EAF0`, `#E4F0F7`, `#D9E6E3`, `#DCEBE7`, `#D8E7E3`, `#D7E4E1`, `#DCEDEA`, `#A9CCE3`, `#CBD5E1` | `border` (garis) / `bg` (latar) / `disabled` (ikon non-aktif) | peran menentukan |
| `#FF6B70`, `#FF5C63`, `#FF6470`, `#E7A5AA` | `danger` | keluar/error |
| `#FFF2F2` | `warnChipBg` | |
| `#FFB43B`, `#FFB131`, `#FFA629`, `#FFC64D`, `#FFD9C5`, `#FFB69F`, `#F4A98E`, `#9B75D6` | hapus / gambar ulang dengan `surfaceWarm`/`primarySoft` | dekorasi tanpa padanan token |
| `#FFFAF1`, `#FFFBF2` | `surfaceWarm` / `bg` | |

Warna ilustrasi painter (`#FFD9C5`, `#5FC7AE`, `#FFC64D`, dst.) di gambar ulang memakai palet token; painter dekoratif di zona fungsional dihapus (D10).

---

## 5. Spesifikasi per layar

### 5.1 Start (`skin_start_page.dart`)
Latar hangat: gradien token (`surfaceWarm` → `bg`) maks ~25% tinggi, sisanya `bg`. Judul besar tetap satu elemen visual khas; teks gradien shader lama (`#1BA18E→#087B6B`) diganti `primary`/`ink` polos atau gradien token. Tombol "Mulai" flat `primary`; link "Masuk" `primary`. Painter dekoratif (`_AccentBurst`, `_Ray`, dst.) disederhanakan memakai palet token (atau dikurangi agar "satu elemen khas per layar"). Tombol tetap memenuhi FR-01 (dua CTA terlihat tanpa scroll di 360×640) — dijaga oleh test.

### 5.2 Masuk (`skin_login_page.dart`)
Token-only: field r12 (dari tema), error inline `danger`, tombol utama flat `primary`, tombol Google nonaktif + "Segera hadir", baris "Demo" (FR-03). Animasi switcher Masuk/Daftar menghormati *reduce motion*. Latar hangat ringan (gradien token, maks 25%).

### 5.3 Beranda (`skin_home_page.dart`) — redesain, pecah file
Struktur atas→bawah:
1. **Header hangat** (maks 25% tinggi): avatar + sapaan pengguna (`ProfileData`), tanpa notifikasi palsu bila tidak berfungsi.
2. **CTA "Mulai scan"** — tombol utama, satu-satunya CTA primer di layar.
3. **Kartu hasil terakhir** — tipe kulit (dari rekomendasi tersimpan terbaru), tanggal, badge "Demo", tombol "Lihat hasil" (→ Result mode baca). Empty state bila belum ada.
4. **Riwayat terbaru** — 3 baris ringkas (tipe + tanggal) + "Lihat semua" → Riwayat.
5. **BottomNav** (D8).
Dihapus: kartu skor, badge kondisi kulit, metrik bar, grafik batang, badge "KULITMU MAKIN SEHAT!", semua angka fallback. File dipecah (`home_hero`, `home_latest`, `home_history_preview`) agar Beranda tidak lagi 1.200+ baris (§12). Ilustrasi hero maksimal satu (`skin_girl`); `skin_analyze_title.png` (judul berupa gambar teks) diganti `Text` asli untuk aksesibilitas. `cat_happy.png` ikut terhapus bersama badge skor.

### 5.4 Quiz (`skin_quiz_page.dart`)
Eyebrow progres menjadi **"Langkah n dari 5"** (12/600, sentence case, `primary`) — bukan `n/5` mentah (FR-04). Progress bar `primarySoft`. Opsi: kartu r16; terpilih = border `primary` + latar `successSoft` + ikon centang. Tombol "Lanjut" nonaktif sampai ada jawaban (FR-05). Tombol kembali antar-soal (tampil saat n>1) mempertahankan jawaban yang sudah dipilih — melengkapi kriteria FR-04 "jawaban tersimpan saat maju/mundur"; tombol tutup tetap membatalkan kuis. Latar netral; `_BreezeBlobs` dihapus. Jawaban tetap dikirim sebagai `quizAnswers` (FR-06).

### 5.5 Scan (`skin_scan_page.dart`)
Token-only; pertahankan logika kamera, consent, batas 10 MB, galeri, error/retry (FR-07–FR-10). `_ScanBackgroundPainter` dihapus (zona fungsional). Bingkai oval & petunjuk cahaya dipertahankan.

### 5.6 Menyusun rekomendasi (`skin_analysis_page.dart`)
Sudah sesuai (skeleton, "Menyusun rekomendasi…", timeout 20 s, retry maks 3). Verifikasi token + komponen `ErrorState`.

### 5.7 Result (`skin_result_page.dart`)
Struktur §9.3 sudah terpasang. Polish: pakai komponen bersama; pastikan chip hindari memakai **ikon peringatan + teks** (FR-19); "Selengkapnya" hanya bila penjelasan > 3 baris; bottom bar CTA `SafeArea`; mode baca (archived) menyembunyikan "Simpan hasil" (FR-22) — sudah; `_UnresolvedNotice` untuk tipe tak dikenal — sudah; tambah badge "Demo". BottomNav tidak ada di layar ini (benar).

### 5.8 Riwayat (`skin_history_page.dart`)
Lihat D4. Pertahankan: sort Terbaru/Terlama, filter tanggal (`showDatePicker`), hapus + konfirmasi (FR-24), empty state dengan CTA "Mulai scan" (FR-23). Baris: tipe kulit + tanggal/jam + status; chevron → Result mode baca. Latar netral; painter dekoratif dihapus. `FutureBuilder` dapat cabang error (D6). Sertakan event `history_deleted` (§14).

### 5.9 Bantuan (`skin_help_page.dart`)
Zona hangat: gradien token maks 25%. Warna teks → `ink`/`inkSecondary`. "Versi 1.1.0" → **"Versi 2.0.0"**. Konten topik dipertahankan (cara scan, cahaya, privasi, arti hasil, kontak). Accordion pakai radius 16 + border token.

### 5.10 Profil (`skin_profile_page.dart`)
Zona fungsional: latar netral (gradien sky lama dihapus). Token-only; badge "Demo" pada data dummy (FR-26); tombol "Keluar akun" danger outline (sudah). Dialog edit/validasi dipertahankan.

---

## 6. Data & kontrak

- `skin_recommendation.dart`: jalur ganda `fromJsonString(String)` (jsonDecode → fromJson) + `fromJson(Map)` diperketat per D6; `toJson` dipertahankan (dipakai test).
- `mock_recommendation_repository.dart`: 5 skenario tetap; isi skenario disimpan sebagai **string JSON mentah** (normal/pendek/panjang/rusak + timeout simulasi); latensi 900 ms, timeout 20 s, `maxRetry = 3` (§8, FR-13/15).
- `skin_history_repository.dart`: seed 3 rekomendasi v2.0; API `saveRecommendation` dipertahankan; `SkinAnalysis` disederhanakan per D5.
- `skin_analysis_page.dart`: alur `decode → map → render`; `FormatException`/`TimeoutException` → `ErrorState` + retry; sukses → Result.
- Test kontrak diperluas: JSON rusak (string bukan objek), tipe field salah di level atas, item list campur baik/rusak, objek kosong, `tipe_kulit` hilang → "Belum dapat ditentukan".

---

## 7. Aksesibilitas, kontras, responsif

- Semua ikon bermakna punya `semanticLabel`; urutan fokus mengikuti urutan baca.
- Chip "hindari": ikon + teks (bukan warna saja) — FR-19.
- Skala teks sampai 1,3× tanpa terpotong; chip `Wrap`; tidak ada scroll horizontal.
- Uji kontras otomatis (baru, `test/token_contrast_test.dart`): hitung rasio WCAG pasangan kunci — `primary`/putih (≈5,6:1), `inkSecondary`/putih (≈5,4:1), `warnChipText`/`warnChipBg` (≈5,6:1), `ink`/`bg`, `primarySoft`/putih dinyatakan **gagal untuk teks kecil** (dokumentasi aturan, bukan bug) → memenuhi DoD "bukti hasil alat uji" §10.3.
- Uji responsif dipertahankan (`responsive_layout_test`, `scan_result_responsive_test`) + target 360×640 & 320.
- Uji alur (§15, baru): Quiz → `SkinAnalysisPage` (byte foto palsu; kamera tidak dapat dikemudikan di test) → Result → Simpan → tampil di Riwayat; plus uji state `SkinAnalysisPage`: loading→sukses, timeout, batas retry 3×, decode gagal.

---

## 8. Rencana bertahap

| Tahap | Isi | Verifikasi |
|---|---|---|
| **1. Tema & Font** | Bundel font (TTF 400/600/700/800) + `ThemeData(fontFamily)`; hapus `google_fonts`; fix `labelLarge`; token: hapus gradient/shadow non-token, siapkan gradien token; test kontras & test fontFamily | `analyze` + `test` hijau; grep `Color(0x` di lib/theme saja |
| **2. Data & Parser** | Mock → string JSON + decode; helper tipe aman; salvage per-item; tipe_kulit longgar; perluas test kontrak; uji state `SkinAnalysisPage` (seam `repository`) | `analyze` + `test`; demo 6 skenario |
| **3. Komponen + layar fungsional** | `lib/widgets/`; migrasi Result, Quiz (eyebrow "Langkah n dari 5" + tombol kembali antar-soal), Scan, Menyusun rekomendasi → komponen + token-only | `analyze` + `test`; grep tiap file tersentuh: 0 hardcode |
| **4. Beranda → data → Riwayat** | Beranda redesain dulu (pecah file); lalu `SkinAnalysis` disederhanakan + seed v2.0 + `FutureBuilder` error + hapus `quiz_scoring`; Riwayat redesain; update `dashboard_history_test`/`history_page_test`; flow test Quiz → Analysis → Result → Riwayat (tanpa kamera) | `analyze` + `test`; manual 360×640 |
| **5. Zona hangat** | Start, Masuk, Bantuan ("Versi 2.0.0"), Profil; hapus gradien/fix warna legacy | `analyze` + `test` |
| **6. Bersih-bersih & DoD** | Hapus alias legacy + kode mati (D5) + aset tak terpakai; sweep akhir; checklist §15 | grep akhir (0 hardcode, 0 alias); `analyze` + `test`; checklist DoD |

Setiap tahap berakhir dengan verifikasi di atas + laporan singkat progres. **Tanpa commit** (D11 revisi) — semua perubahan dibiarkan di working tree.

---

## 9. Definition of Done (peta §15)

| Item §15 | Cara verifikasi |
|---|---|
| Semua layar lolos 360×640 tanpa overflow | test responsif + smoke manual masing-masing tahap |
| Tidak ada warna hardcode di luar token §10 | grep `Color(0x` hanya di `lib/theme/app_tokens.dart` (+ pengecualian terdokumentasi) |
| Font Plus Jakarta Sans tampil (bundel asset, tidak jatuh ke bawaan) | blok `fonts:` di pubspec + widget test `fontFamily` |
| Result menangani 3 panjang konten + 1 JSON rusak | `recommendation_contract_test` diperluas |
| Kontras memenuhi §10.3 | `token_contrast_test` + catatan pasangan yang dilarang |
| Disclaimer & consent tampil | sudah; verifikasi visual |
| Semua label Indonesia sesuai glosarium §9.5 | sweep copy (sentence case, "Mulai scan" satu nama) |
| Dokumen versi ini disetujui dosen pembimbing | di luar sesi kode; dokumen ini diserahkan ke tim |

---

## 10. Keputusan pengguna (dikonfirmasi 17 Okt 2026)

| # | Pertanyaan | Keputusan |
|---|---|---|
| ⚑1 | Skor dimatikan total di Beranda & Riwayat (D3/D4), termasuk mengganti data seed? | **Ya** — kontrak §8 tidak memuat skor; ini inti pergeseran v2.0 |
| ⚑2 | `scoreQuiz` + test-nya dihapus (D5)? | **Ya** — tidak dipakai UI, §17 no.2 memberi opsi hapus |
| ⚑3 | Pernyataan usia minimum di form Daftar (§13, §17 no.6)? | Tampilkan satu baris "Dengan mendaftar, kamu menyatakan berusia 17 tahun atau lebih" (sesuai asumsi §17) |

---

## 11. Risiko

| Risiko | Mitigasi |
|---|---|
| Unduhan font gagal (jaringan) | coba beberapa sumber resmi; bila gagal, minta TTF dari tim (struktur sama) |
| Redesain Beranda memecah test lama | update test bersamaan di tahap 4; jaga test lain tetap hijau tiap tahap |
| Migrasi warna menyisakan varian visual | grep-audit tiap tahap + tabel §4 sebagai acuan tunggal |
| Perubahan besar pada file panjang (Beranda 1.222 baris) | pecah file + verifikasi bertahap; diff tetap dapat direview per tahap tanpa commit |
| `skinsight-figma.html` (belum di-commit) | tidak disentuh; tidak masuk commit mana pun |

---

## 12. Lampiran — baseline audit (17 Okt 2026)

- `Color(0x…)` di lib/: **125 literal di file halaman** (+20 definisi token); `Colors.*`: 70 (white 58 / transparent 12).
- `TextStyle(` inline di luar tema: **91**; GoogleFonts: 1 file (`app_theme.dart`).
- Komponen duplikat: header back ×5, bottom-nav ×3; tidak ada `lib/widgets/`.
- Font: `google_fonts` runtime; `pubspec` tanpa blok `fonts:`.
- Kode mati: `quiz_scoring.dart` (+1 test), `saveLatest`, route `/result`, dep `flutter_animate`; 8 PNG tak terpakai (`bubbles`, `city_background`, `clouds`, `description_sticker`, `hero_decor`, `leaves_flowers`, `sparkles`, `try_now_sticker`).
- Parser: tanpa `dart:convert`; `TypeError` top-level lolos ke catch generik; 1 item rusak = seluruh daftar aktif/referensi hilang; `FutureBuilder` menelan error.
- Teks usang: "Versi 1.1.0" di `skin_help_page.dart:551`.
