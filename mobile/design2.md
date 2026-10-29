# SkinSight v2.0 — Desain per Halaman (Spec Implementasi)

> **Apa ini?** Rekaman desain **setiap halaman** SkinSight v2.0 *sebagaimana diimplementasikan* di aplikasi Flutter (bukan mockup). Cocok dipakai tim dev, QA, dan desainer untuk menyelaraskan tampilan dengan kode.
>
> **Sumber kebenaran:** PRD SkinSight v2.0 §9–§11 dan kode di `lib/theme/`, `lib/widgets/`, `lib/pages/`. Jika kode berubah, dokumen ini menyusul.
>
> **Konteks produk:** Flutter + Material 3, **light mode saja**, copy Bahasa Indonesia, aplikasi **demo** (konten analisis tiruan ditandai badge "Demo"). Semua warna/teks berasal dari design token — literal `Color(0x…)` hanya boleh hidup di `lib/theme/app_tokens.dart`.

- Versi aplikasi: **2.0.0**
- Tanggal sinkronisasi dokumen: **Oktober 2026**

---

## 1. Sistem Desain

### 1.1 Warna (kanonik) — `lib/theme/app_tokens.dart`

| Token | Nilai HEX | Peran |
|---|---|---|
| `primary` | `#087467` | Warna merek; tombol utama, aksen aktif, ikon kunci |
| `primarySoft` | `#168A78` | Aksen sekunder; fokus input, kata "Sight", ikon lembut |
| `ink` | `#13263A` | Teks utama (judul & badan) |
| `inkSecondary` | `#5A6D78` | Teks pendukung/caption, tab non-aktif |
| `disabled` | `#9AA9B0` | Teks/ikon nonaktif, hint, chevron |
| `bg` | `#F4F6F6` | Latar halaman (netral) |
| `surface` | `#FFFFFF` | Permukaan kartu, bilah, tombol putih |
| `surfaceWarm` | `#FFF8EB` | Permukaan zona hangat (gradien) & disclaimer |
| `border` | `#E2E9E7` | Garis tepi kartu, divider, garis input |
| `successSoft` | `#E3F4F0` | Latar chip/badge/pilihan aktif (hijau lembut) |
| `warnChipBg` | `#FFF0F0` | Latar peringatan (chip "di hindari", notis warn) |
| `warnChipText` | `#B3303A` | Teks/ikon peringatan |
| `danger` | `#E6535F` | Aksi merusak (hapus, keluar), error |
| `info` | `#35A9EE` | Aksen info (ikon topik Bantuan) |
| `transparent` | `transparent` | Utilitas (mis. mematikan divider `ExpansionTile`) |

**Gradien zona hangat** — `AppTokens.warmGradient`: `surfaceWarm → bg` (atas → bawah). Hanya untuk header/hero, **maks kira-kira 25% tinggi layar**, selalu memudar ke `bg`.

**Kartu** — `AppTokens.card()`: `surface` + border 1px `border` + radius `r16` + bayangan `primary` 6% (blur 12, offset `0,4`). Dipakai lewat widget `SectionCard`.

**Pengecualian warna non-token (terdokumentasi):** mark Google `#4285F4` di `skin_login_page.dart` (warna brand pihak ketiga).

### 1.2 Tipografi — peran `AppTokens.*` (font: **Plus Jakarta Sans**, dibundel)

| Peran | Ukuran | Berat | Tinggi baris | Warna | Pemakaian umum |
|---|---|---|---|---|---|
| `display` | 28 | w800 | 1.15 | `ink` | Judul hero Start |
| `h1` | 24 | w700 | 1.2 | `ink` | Judul halaman, nama profil |
| `h2` | 20 | w700 | 1.25 | `ink` | Judul header layar, judul seksi |
| `title` | 16 | w700 | 1.3 | `ink` | Judul kartu, judul item |
| `body` | 15 | w400 | 1.5 | `ink` | Isi teks, label opsi |
| `caption` | 13 | w400 | 1.4 | `inkSecondary` | Teks pendukung, tanggal, hint |
| `eyebrow` | 12 | w600 | — | `primary` | Label kecil di atas judul ("Langkah 1 dari 5", "Hasil terakhir") |

Catatan: peran adalah *getter* — dilarang dipakai di konstruktor `const`; gunakan `AppTokens.h2.copyWith(...)` untuk variasi.

### 1.3 Spacing & radius

- Spasi: `s4`, `s8`, `s12`, `s16`, `s20`, `s24` (kelipatan 4/8).
- Radius: `r12` (input, chip), `r16` (kartu, tombol, opsi), `r20` (frame kamera, sudut bawah header hangat).
- Target sentuh minimum: **48×48** (`AppLayout.minTouch`).

### 1.4 Layout & responsivitas — `lib/theme/app_layout.dart`

| Konstanta | Nilai | Catatan |
|---|---|---|
| `maxWidth` | 520 | Lebar konten HP (di-center) |
| `tabletMaxWidth` | 720 | Konten saat lebar ≥ 600 |
| `compactBreakpoint` | 360 | Di bawah ini margin menyempit |
| `wideBreakpoint` | 600 | Ambang tablet |
| `marginStandard` / `marginCompact` | 16 / 12 | Margin horizontal halaman |
| `sectionGap` / `cardGap` / `cardPadding` | 24 / 12 / 16 | Jarak antar-seksi, antar-kartu, padding kartu |

Perilaku responsif: konten dibungkus `Center + ConstrainedBox`; halaman penting sudah diuji pada **320/360/390/412** lebar dan **360×640** (tanpa overflow) serta `textScale` 1.3 di layar Hasil.

### 1.5 Tema komponen global — `lib/theme/app_theme.dart`

- **FilledButton**: latar `primary`, teks `surface` 16 w700, min 160×48, radius `r16`.
- **OutlinedButton**: teks `primary`, border `border`, min 160×48, radius `r16`.
- **Input (TextFormField)**: terisi `surface`, radius `r12`, padding 14; fokus `primarySoft` 2px; error `danger`; label `inkSecondary`; hint `disabled`.
- **Card**: `surface`, elevasi 0, radius `r16`, border `border`.
- **Chip**: latar `successSoft`, radius `r12`.
- **Scaffold**: latar `bg`.

### 1.6 Komponen bersama — `lib/widgets/`

| Widget | Fungsi & gaya |
|---|---|
| `ScreenHeader` | Header layar: tombol kembali bulat 48 (ikon `ink`, tooltip "Kembali") + judul `h2` + slot aksi. Dipakai di Scan, Hasil, Riwayat, Bantuan, Profil. |
| `SectionCard` | Kartu permukaan `AppTokens.card()`, padding default 16; opsi `shadow: false` di atas gradien, `padding: zero` untuk daftar berbagi garis. |
| `SightBottomNav` | Navigasi bawah 4 tab (Beranda, Riwayat, Bantuan, Profil) + FAB tengah "Mulai scan" (lingkaran `primary` 60, ikon kamera putih, cincin `surface` 4). Tab aktif `primary` w700; non-aktif `inkSecondary`. Bilah mereservasi 22px (`fabOverhang`) agar kepala FAB bisa di-tap. |
| `StatusNotice` | Notis ringkas biru lembut/hangat: tone `info` (`successSoft`/`primary`), `warn` & `error` (`warnChipBg`/`warnChipText`). |
| `EmptyState` | Keadaan kosong jujur: ikon 48 `disabled`, judul `title`, pesan `caption`, aksi opsional. Tanpa angka palsu. |
| `ErrorState` | Keadaan gagal: ikon `cloud_off` 48, judul + pesan, tombol "Coba lagi" + aksi sekunder opsional. |
| `AvoidChip` | Chip zat yang dihindari: latar `warnChipBg`, ikon peringatan 18 `warnChipText`, teks `warnChipText`; aman di dalam `Wrap`. |
| `StepList` | Daftar langkah bernomor: bulatan 24 `primary`, angka putih w700, teks `body`. |
| `DemoBadge` | Label "Demo": latar `successSoft`, teks `caption` `primary` w700, radius `r12`. |

### 1.7 Peta halaman

| # | Halaman | File | Zona |
|---|---|---|---|
| 1 | Start | `lib/pages/skin_start_page.dart` | Hangat |
| 2 | Masuk / Daftar | `lib/pages/skin_login_page.dart` | Hangat |
| 3 | Beranda | `lib/pages/skin_home_page.dart` + `lib/pages/home/*` | Hangat (header) + fungsional |
| 4 | Kuis kondisi kulit | `lib/pages/skin_quiz_page.dart` | Fungsional |
| 5 | Scan wajah | `lib/pages/skin_scan_page.dart` | Fungsional |
| 6 | Menyusun rekomendasi | `lib/pages/skin_analysis_page.dart` | Fungsional |
| 7 | Hasil rekomendasi | `lib/pages/skin_result_page.dart` | Fungsional |
| 8 | Riwayat | `lib/pages/skin_history_page.dart` | Fungsional |
| 9 | Bantuan | `lib/pages/skin_help_page.dart` | Hangat |
| 10 | Profil | `lib/pages/skin_profile_page.dart` | Fungsional |

Prinsip visual lintas halaman: **satu hero per layar**, tanpa skor/grafik/angka dekoratif, tanpa notifikasi palsu, konten tiruan selalu ber-badge "Demo".

---

## 2. Start — `lib/pages/skin_start_page.dart`

**Peran:** layar pembuka / gerbang masuk aplikasi. Dua CTA harus terlihat tanpa scroll di layar kecil (FR-01).

**Zona & latar:** zona hangat — gradien `warmGradient` menutupi 25% atas layar, sisanya `bg`.

**Anatomi (atas → bawah):**
1. **Brand**: mark merek 34×34 (`CustomPaint`: cincin `primarySoft` + titik dan 8 titik `primary`) + wordmark "Skin" (`primary`) "Sight" (`primarySoft`), huruf `h1` dengan letterSpacing −0.8.
2. **Hero**: satu gambar `assets/images/start_avatar.png`, maks 300×300, `contain`, di tengah ruang kosong fleksibel.
3. **Judul**: "Start your\n**skin journey**" — baris kedua `primary`.
4. **Subjudul**: "Kenali kondisi kulitmu\nuntuk perawatan yang tepat." (`body`, `inkSecondary`, tengah).
5. **CTA primer**: tombol `FilledButton` penuh lebar **"Mulai"**.
6. **CTA sekunder**: `TextButton` "Sudah punya akun? Masuk".

**Token & komponen:** `warmGradient`, peran `display`/`h1`/`body`, tombol tema global. Lebar konten dikunci 520; padding horizontal 24 (20 saat lebar < 350).

**State:** stateless (tanpa loading/error).

**Interaksi & navigasi:**
- "Mulai" → `/login` (`pushReplacementNamed`). Key: `start-button`.
- "Sudah punya akun? Masuk" → `/login` (efek sama). Key: `start-login`.

**Copy kunci:** "Start your skin journey", "Kenali kondisi kulitmu untuk perawatan yang tepat.", "Mulai", "Sudah punya akun? Masuk".

**A11y:** gambar hero punya `semanticLabel` "Ilustrasi perawatan kulit SkinSight".

---

## 3. Masuk / Daftar — `lib/pages/skin_login_page.dart`

**Peran:** autentikasi demo (satu layar dua mode: **Masuk** dan **Daftar**), plus tombol Google nonaktif berlabel "Segera hadir" (FR-03) dan pernyataan usia pada mode Daftar (§13).

**Zona & latar:** zona hangat — gradien `warmGradient` 25% atas; konten scroll di bawahnya.

**Anatomi (atas → bawah):**
1. **Brand**: ikon `blur_circular_rounded` (`primarySoft`) + wordmark "SkinSight" (`h1`).
2. **Avatar**: `start_avatar.png` dalam bulatan 96–112 px, cincin `surface` + border `border`.
3. **Kepala mode** (`AnimatedSwitcher` 180 ms, hormat `disableAnimations`):
   - Masuk: judul "Selamat datang kembali" + badge **Demo** + "Masuk untuk melanjutkan perjalanan kulitmu."
   - Daftar: judul "Buat akun SkinSight" + badge **Demo** + "Mulai kenali kondisi kulitmu dengan akun baru."
4. **Form**:
   - Mode Daftar: "Nama lengkap" (wajib).
   - "Alamat email" (pra-terisi `alea@skinsight.id`; validasi wajib + harus memuat `@`).
   - "Password" (pra-terisi `skinsight123`; min 6 karakter; ada tombol lihat/sembunyikan password).
5. **Submit**: "Masuk" / "Daftar" (`FilledButton` penuh lebar).
6. **Mode Daftar**: catatan "Dengan mendaftar, kamu menyatakan berusia 17 tahun atau lebih."
7. **Mode Masuk**: pembatas "— atau —", tombol outline **"Masuk dengan Google"** (nonaktif, mark `G` biru brand), teks kecil "Segera hadir".
8. **Footer**: "Belum punya akun? **Daftar**" ⇄ "Sudah punya akun? **Masuk**" (toggle mode; form di-reset; scroll kembali ke atas).

**Komponen:** field memakai tema input global (r12, fokus `primarySoft`), ikon awalan `person/mail/lock` `primarySoft`, teks isian `body` w600.

**State:** mode `_registerMode`, visibilitas password, validasi per-field; tanpa loading jaringan (demo).

**Interaksi & navigasi:**
- Submit valid → `pushNamedAndRemoveUntil('/home')` (tumpukan dibersihkan). Key: `login-submit`.
- Toggle mode: `login-register-toggle`; nama: `register-name`; email: `login-email`; password: `login-password` + `login-password-visibility`; Google: `login-google`.

**Copy validasi:** "Nama perlu diisi.", "Email perlu diisi." / "Masukkan alamat email yang valid.", "Password minimal 6 karakter."

**Responsif & a11y:** scroll aman di 360×640 (`login-scroll`); padding 20/28 menurut lebar; tooltip pada toggle password.

---

## 4. Beranda — `lib/pages/skin_home_page.dart` (+ `lib/pages/home/`)

**Peran:** pusat kendali harian — sapaan, CTA scan, hasil terakhir, dan cuplikan riwayat (maks 3 baris).

**Zona & latar:** header zona hangat (satuan `HomeWarmHeader`), sisanya fungsional `bg`.

**Anatomi (atas → bawah):**
1. **Header hangat** — `HomeWarmHeader`:
   - Gradien `warmGradient` dengan sudut bawah membulat `r20`; padding 20 sisi.
   - Kiri: "Halo," (`caption`) + nama pengguna (`h1`, ellipsis; fallback "Sahabat" bila kosong).
   - Kanan: avatar bulat 52 (foto pengguna atau huruf awal `h2` `primary`), cincin `surface`; ketuk → Profil. Key: `open-profile`.
2. **CTA primer** — `FilledButton.icon` "Mulai scan" (ikon `center_focus_strong`) penuh lebar. Key: `open-quiz-try`.
3. **Kartu hasil terakhir** — `HomeLatestCard` (`SectionCard`):
   - Ada data: eyebrow "Hasil terakhir" + badge **Demo**; tipe kulit (`title`); tanggal format "3 Okt 2026" (`caption`); tombol "Lihat hasil" penuh lebar. Key: `home-view-latest`.
   - Belum ada data: `EmptyState` ikon `face_retouching_natural`, judul "Belum ada hasil", pesan "Mulai scan untuk mendapat rekomendasi pertamamu.", tombol "Mulai scan". Key: `home-start-empty`.
4. **Cuplikan riwayat** — `HomeHistoryPreview`:
   - Header "Riwayat" (`h2`) + "Lihat semua" (TextButton). Key: `open-history-all`. Tidak tampil bila riwayat kosong.
   - Baris item (maks 3): kotak ikon 36 `successSoft`/`spa` → tipe kulit (`body` w700) + tanggal (`caption`) → chevron `disabled`; permukaan kartu `surface` r16 border. Key: `history-preview-row`.
5. **Bilah navigasi** — `SightBottomNav(active: beranda)`.

**State:**
- **Memuat pertama**: skeleton kartu tinggi 160 (`_LatestCardSkeleton`) — menghindari kedip `EmptyState` sebelum data tiba.
- **Gagal**: `ErrorState` "Gagal memuat data Beranda." + "Coba lagi".
- **Data berubah**: mendengarkan `SkinHistoryRepository.revision` → muat ulang otomatis.

**Interaksi & navigasi:**
- CTA/FAB → Kuis (`push`); baris riwayat & "Lihat hasil" → Hasil mode arsip (`archived: true`); "Lihat semua" → `/history`.

**Responsif:** margin 12/16 sesuai lebar; konten maks 520 (720 tablet).

---

## 5. Kuis kondisi kulit — `lib/pages/skin_quiz_page.dart`

**Peran:** lima pertanyaan singkat (FR-03..FR-06) sebagai konteks untuk rekomendasi. Maju otomatis per jawaban, bisa mundur tanpa kehilangan jawaban.

**Zona & latar:** fungsional murni — latar `bg` polos.

**Anatomi:**
1. **Bilah atas** `_QuizTopBar`:
   - Tombol kembali bulat 48 (`surface` + border) saat bukan pertanyaan pertama. Key: `quiz-back-question`.
   - Tengah: eyebrow "**Langkah n dari 5**" + bilah progres 8px membulat (`primarySoft` di atas `border`, nilai n/5).
   - Kanan: tombol tutup bulat 48 (ikon ×, `inkSecondary`) → membatalkan kuis (pop). Key: `quiz-back`.
2. **Pertanyaan**: judul `h2` rata tengah, subjudul `caption` rata tengah.
3. **Opsi jawaban** `_QuizOption` — kartu pilihan tinggi min 56, radius `r16`:
   - Belum dipilih: `surface` + border `border`; lingkaran radio 22 kosong.
   - Dipilih: latar `successSoft`, border `primary` 1.6px, radio terisi titik `primary`.
   - Label opsi `body` w600 (1 baris, ellipsis). Key: `quiz-answer-0..3`.
4. **Tombol bawah**: "Lanjut" (atau **"Selesai"** di pertanyaan 5), penuh lebar, nonaktif sampai jawaban dipilih. Key: `quiz-continue`.

**Konten:** 5 pertanyaan × 4 opsi, judul pertanyaan:
1. "Bagaimana rasa kulit wajahmu saat bangun pagi?"
2. "Seberapa sering kulitmu terasa sensitif?"
3. "Bagaimana kondisi pori-porimu?"
4. "Masalah kulit apa yang paling mengganggumu?"
5. "Berapa lama kamu berada di luar ruangan?"

**State:** jawaban tersimpan per indeks (tidak ada auto-isi, FR-05); mundur mempertahankan jawaban (FR-04).

**Interaksi & navigasi:**
- "Lanjut" tanpa jawaban → SnackBar "Pilih salah satu jawaban terlebih dahulu."
- Selesai → `pushReplacement` ke **Scan** dengan `quizAnswers` (FR-06).

**A11y:** tiap opsi `Semantics(button, selected)` dengan label gabungan judul + penjelasan opsi.

---

## 6. Scan wajah — `lib/pages/skin_scan_page.dart`

**Peran:** ambil foto selfie (kamera) atau pilih dari galeri, dengan persetujuan privasi sekali di awal (FR-07).

**Zona & latar:** fungsional.

**Anatomi:**
1. **Header** `ScreenHeader` "Scan Wajah" (kembali = pop).
2. **Frame kamera** `_CameraFrame` — tinggi 360 (compact) / 440:
   - Bingkai putih `surface` radius `r20` + bayangan kartu, isi pratinjau radius `r16`.
   - Overlay pemandu wajah (`_FaceGuidePainter`): oval putih 70% + oval putus-putus `primary` + 4 siku sudut `primary`.
   - Pil bawah di dalam frame (`ink`, teks `surface` w700): "Posisikan wajah di dalam frame".
   - Kondisi: memuat → spinner `primary` di atas `bg`; gagal → ikon `no_photography` + pesan + tombol "Coba lagi" (key `retry-camera`).
3. **Sakelar mode** `_ModeSwitch` — dua segmen "Foto Otomatis" / "Foto Manual", tinggi 52/56, segmen aktif `primary` (teks `surface`), transisi 180 ms (dimatikan bila `disableAnimations`).
4. **Zona jempol (sticky bawah, selalu tanpa scroll)** — bilah `surface` ber-border atas:
   - Tombol galeri 66×66 (r16, border; ikon `primary`, nonaktif → `disabled`). Key: `scan-gallery`.
   - **Tombol shutter** bulat 82/94: cincin `primary` 4px, inti `primary`; saat memotret berubah spinner. Key: `capture-selfie`.
   - Tombol ganti kamera 66×66 (aktif hanya bila >1 kamera). Key: `switch-camera`.
   - Hint `caption` 1 baris: mode otomatis — "Hadap cahaya, lepas kacamata. Posisikan wajah di dalam frame."; mode manual — "Mode manual. Hadap cahaya, lepas kacamata."

**Kebijakan & batasan:** foto > 10 MB ditolak (SnackBar); izin kamera ditolak → pesan arahan ke Pengaturan/galeri; daur hidup aplikasi: kamera dilepas saat app inactive, inisialisasi ulang saat resume; galeri via `ImagePicker` (kualitas 90, maks 1600).

**Dialog persetujuan (sekali sebelum foto pertama):**
- Judul: "Izin penggunaan foto"; isi merujuk UU PDP No. 27/2022; foto disimpan di perangkat dan bisa dihapus kapan saja.
- Aksi: "Batal" / **"Setuju dan lanjutkan"**; `barrierDismissible: false`.

**Interaksi & navigasi:** setelah foto siap → `pushReplacement` ke **Menyusun rekomendasi** (`quizAnswers` diteruskan; tanpa kuis → `lowAccuracy: true`).

---

## 7. Menyusun rekomendasi — `lib/pages/skin_analysis_page.dart`

**Peran:** status proses analisis (FR-11..FR-15) tanpa progres palsu; timeout 20 dtk; retry maksimal 3×.

**Zona & latar:** fungsional; konten maks 520.

**Anatomi:**
1. **Memuat** (`_LoadingBody`, key `analysis-loading`): spinner `primary` → "**Menyusun rekomendasi…**" (`title`) → 3 kartu skeleton tinggi 64 (`surface` r16 border) sebagai isyarat tata letak hasil.
2. **Gagal** (`ErrorState`, key `analysis-error`): judul "Gagal menyusun rekomendasi"; pesan sesuai sebab (timeout / hasil tidak terbaca); aksi utama **"Coba lagi"** (key `analysis-retry`, hilang setelah batas 3 percobaan — berganti pesan "Batas percobaan tercapai (3×)…"); aksi sekunder "Ulangi foto" (kembali/pop).

**State:** `_attempt`, `_error`; sukses → `pushReplacement` ke **Hasil**. Analytics: `analysis_requested` / `analysis_success` / `analysis_failed {reason}`.

**Copy kunci:** "Menyusun rekomendasi…", "Gagal menyusun rekomendasi", "Coba lagi", "Ulangi foto".

---

## 8. Hasil rekomendasi — `lib/pages/skin_result_page.dart`

**Peran:** layar hasil (§7.5, §9.3): rekomendasi terstruktur dengan tanda tangan visual **timeline rutinitas pagi/malam** (bukan cincin skor). Mendukung dua mode: hasil baru dan **arsip** (dari Riwayat). Bilah navigasi bawah **tidak tampil** di sini.

**Zona & latar:** fungsional `bg`.

**Anatomi (atas → bawah):**
1. **Header** `ScreenHeader` "Hasil Rekomendasi" + badge **Demo** di kanan; tombol kembali memicu konfirmasi "Buang hasil?" bila hasil belum disimpan.
2. **Notis kontekstual** (opsional): foto saja → "Hasil memakai foto saja tanpa quiz, akurasi lebih rendah."; mode arsip → "Hasil scan tersimpan" (ikon centang).
3. **Kartu tipe** `_TipeCard`: eyebrow "Hasil analisis" → tipe kulit (`h1`) → penjelasan singkat (`body`, dipotong 140 karakter + tombol "Selengkapnya"/"Tutup").
4. **Notis tipe tak pasti** (bila berlaku): "Belum dapat ditentukan. Ulangi foto dengan pencahayaan lebih baik." (tone warn).
5. **Kartu rutinitas** `_RoutineCard` — tanda tangan halaman: judul "Rutinitas" + dua tombol segmen **Pagi**/**Malam** (aktif `primary`/`surface`; non-aktif `successSoft`/`primary`; tinggi 48) + `StepList` langkah bernomor. Bila kosong: "Belum ada langkah. Lakukan scan ulang."
6. **Kartu zat aktif cocok** `_ActivesCard`: daftar nama (`body` w700) + fungsi (`caption`) + divider; lebih dari 3 item → tombol "Lihat semua"/"Tutup" (key `zat-lihat-semua`).
7. **Kartu zat dihindari** `_AvoidCard`: `Wrap` berisi `AvoidChip` merah lembut.
8. **Kartu tambahan** `_MoreCard`: dua `ExpansionTile` — "Perawatan tambahan" (daftar centang `primarySoft`) dan "Referensi" (subjudul "Rujukan umum, belum diverifikasi").
9. **Disclaimer** `_DisclaimerCard`: permukaan `surfaceWarm` r12 border + ikon medis; teks "Hasil ini panduan umum, bukan diagnosis. Lakukan uji tempel…". Key: `disclaimer`.
10. **CTA bawah (sticky)**: "Scan ulang" (`OutlinedButton`, key `scan-ulang`) + "Simpan hasil" (`FilledButton`, key `save-result`; berubah spinner saat menyimpan; disembunyikan di mode arsip / setelah tersimpan).

**State kosong:** `EmptyState` "Data tidak tersedia" + tombol "Scan ulang" bila rekomendasi null.

**Interaksi & navigasi:**
- Kembali saat belum disimpan → dialog "Buang hasil?" ("Tetap"/"Buang").
- "Simpan hasil" → repo riwayat + SnackBar "Hasil berhasil disimpan ke riwayat."; gagal → "Gagal menyimpan. Coba lagi."
- "Scan ulang" → mendorong layar Scan baru.
- Analytics: `result_saved`, `result_rescan`.

**Responsif & a11y:** diuji 360×640 dan `textScale` 1.3; format teks tahan 3 panjang konten + 1 kasus rusak (fallback).

---

## 9. Riwayat — `lib/pages/skin_history_page.dart`

**Peran:** daftar hasil scan tersimpan (§7.5) dengan kontrol urut, filter tanggal, dan hapus berkonfirmasi. Tanpa skor/metrik.

**Zona & latar:** fungsional.

**Anatomi:**
1. **Header** `ScreenHeader` "Riwayat" + aksi kanan tombol kalender bulat (tooltip "Filter tanggal"; key `history-filter-date`).
2. **Kontrol daftar** `_ListControls`: eyebrow "Daftar scan" + tombol urut "Terbaru ↓"/"Terlama ↑" (key `history-sort-toggle`); bila ada filter tanggal → `ActionChip` tanggal "03 Okt" dengan ikon × untuk menghapus filter (key `clear-history-filter`).
3. **Daftar kartu** `_HistoryRow` (satu per hasil):
   - Kotak ikon 40 `successSoft` r12 + ikon `spa` `primary`.
   - Tipe kulit (`title`, ellipsis) + tanggal-waktu "03 Okt · 14:05" (`caption`).
   - Tombol hapus (ikon tempat sampah `inkSecondary`, tooltip "Hapus"). Key: `history-delete-<id>`.
   - Chevron `disabled`; seluruh baris dapat diketuk. Key: `history-detail-<id>`.
4. **Bilah navigasi** `SightBottomNav(active: riwayat)`.

**State:**
- **Memuat**: skeleton 3 kartu tinggi 68 (bukan spinner).
- **Kosong**: `EmptyState` ikon `history`, "Belum ada riwayat" + pesan berbeda untuk "belum pernah" vs "tidak ada pada tanggal ini" + tombol "Mulai scan" (key `history-empty-scan`).
- **Gagal**: `ErrorState` "Gagal memuat riwayat." + "Coba lagi".

**Interaksi & navigasi:**
- Filter tanggal via `showDatePicker` ("Pilih tanggal scan", Batal/Pilih; rentang 2024–2030).
- Hapus → dialog "Hapus riwayat?" — "«tipe» beserta fotonya akan dihapus permanen." ("Batal"/"Hapus" merah) → SnackBar "Riwayat dihapus."
- Ketuk kartu → **Hasil** mode arsip (`archived: true`).
- Perubahan repo memicu muat ulang daftar otomatis.

---

## 10. Bantuan — `lib/pages/skin_help_page.dart`

**Peran:** pusat bantuan (§5.9): panduan pakai, FAQ, kontak, privasi, tentang.

**Zona & latar:** zona hangat — gradien `warmGradient` 25% atas.

**Anatomi:**
1. **Header** `ScreenHeader` "Pusat Bantuan".
2. **Kartu sambutan** `_WelcomeCard`: bulatan 56 `successSoft` + ikon `volunteer_activism` `primary`; judul "Ada yang bisa kami bantu?" (`title`) + "Pilih topik di bawah untuk menemukan informasi yang kamu butuhkan." (`caption`).
3. **Panel topik** `_HelpTopicsPanel` (`SectionCard` padding nol, satu kartu berisi 5 accordion dipisah divider indent 74):
   1. **Cara menggunakan SkinSight** (ikon kilau `auto_awesome`, tone `primarySoft`) — 3 langkah bernomor: isi kuis → ambil selfie → lihat hasil.
   2. **FAQ** (tone `info`) — 5 tanya-jawab: diagnosis medis? kualitas foto? ulang scan? foto disimpan? cara membaca hasil?
   3. **Hubungi kami** (tone `danger`) — kartu `warnChipBg` r16: "Email dukungan / support@skinsight.app" + tombol salin (key `copy-support-email`) → SnackBar "Email dukungan berhasil disalin."
   4. **Kebijakan privasi** (tone `primary`) — paragraf: foto dipakai di perangkat, tersimpan hanya bila menekan "Simpan".
   5. **Tentang SkinSight** (tone `inkSecondary`) — deskripsi aplikasi + "**Versi 2.0.0**" (`title` `primary`).
   - Baris topik: kotak ikon 44 r12 (warna tone 13% alfa) + judul `title` + subjudul `caption`; chevron `primary` saat terbuka / `inkSecondary` saat tertutup; konten memiliki divider `border` tipis.
4. **Bilah navigasi** `SightBottomNav(active: bantuan)`.

**Detail implementasi:** `ExpansionTile` dibungkus `Material(transparency)` agar splash `ListTile` tampil di atas kartu berdekorasi; divider bawaan `ExpansionTile` dinolkan lewat `Theme`.

**A11y:** konten scroll memakai key `help-scroll`; ikon sambutan punya label "Bantuan".

---

## 11. Profil — `lib/pages/skin_profile_page.dart`

**Peran:** identitas pengguna dan pengaturan akun demo (§5.10): ubah foto, nama, password, telepon, email; keluar akun (FR-26: badge Demo).

**Zona & latar:** fungsional — `bg` polos (gradien lama dihapus).

**Anatomi:**
1. **Header** `ScreenHeader` "Profil Saya".
2. **Identitas** `_IdentitySection`:
   - Avatar 116 bulat: latar `successSoft`, cincin `surface` 5, bayangan `primary` 16%; isi foto pengguna atau **inisial** (`display` `primary`); tombol edit 48 bulat `primarySoft` menempel kanan-bawah (key `edit-profile-photo`).
   - Nama (`h1`, key `profile-name-heading`) + "Akun SkinSight" (`caption`) + badge **Demo**.
3. **Kartu data** `_ProfileFields` (`SectionCard` padding nol; baris dipisah divider indent 51):
   - Nama (ikon `person`), Password (ikon `lock`, nilai "••••••••••••"), Nomor telepon (`phone`), Alamat email (`mail`).
   - Tiap baris: label `caption` w600 + nilai `body` w700 (ellipsis) + tombol edit `primary` (tooltip "Edit {label}"). Key: `edit-profile-name/password/phone/email`.
4. **Keluar akun** `_LogoutButton`: `OutlinedButton.icon` penuh lebar, warna & border `danger`, tinggi 54, ikon logout. Key: `logout-account`.

**Dialog:**
- **Ubah nilai** (nama/telepon/email): `AlertDialog` + `TextField` (key `profile-edit-input`) + "Batal"/"Simpan" (key `save-profile-edit`; kosong = tidak tersimpan).
- **Ubah password**: field "Password baru" + "Ulangi password"; validasi "Minimal 8 karakter." / "Password tidak sama."; sukses → SnackBar "Password berhasil diperbarui."
- **Keluar akun**: "Keluar dari akun?" — "Kamu perlu masuk kembali untuk membuka data akun SkinSight." — "Batal"/"Keluar" (`danger`, key `confirm-logout`) → kembali ke rute pertama tumpukan + SnackBar "Kamu telah keluar dari akun."
- **Ubah foto**: bottom sheet `surfaceWarm` ("Ubah foto profil") dengan "Ambil foto" / "Pilih dari galeri" (keys `profile-photo-camera`/`profile-photo-gallery`; galeri/kamera via `ImagePicker` kualitas 88, maks 1200).

**Bilah navigasi:** `SightBottomNav(active: profil)`.

---

## 12. Peta Navigasi

```
'/' Start
 └─(Mulai / Sudah punya akun? Masuk)──▶ '/login'                 [pushReplacement]
      └─(Submit valid)──▶ '/home'                                [pushNamedAndRemoveUntil]

'/home'  (tab Beranda)
 ├─ CTA "Mulai scan" / FAB tengah ─▶ Kuis                       [push]
 │    └─(Selesai)──▶ Scan                                        [pushReplacement]
 │         └─(Foto siap)──▶ Menyusun rekomendasi                 [pushReplacement]
 │              └─(Sukses)──▶ Hasil                              [pushReplacement]
 │                   ├─(Simpan)──▶ tersimpan di Riwayat
 │                   ├─(Kembali & belum simpan)──▶ konfirmasi "Buang hasil?"
 │                   └─(Scan ulang)──▶ Scan                      [push]
 ├─(Lihat hasil / baris riwayat)──▶ Hasil (arsip, tanpa tombol Simpan)
 └─ BottomNav (kecuali di Kuis/Scan/Menyusun/Hasil):
      Beranda  ◀ popUntil
      Riwayat ─▶ '/history'   [pushNamedAndRemoveUntil]   └─ baris ─▶ Hasil (arsip)
      Bantuan ─▶ '/help'      [pushNamedAndRemoveUntil]
      Profil  ─▶ '/profile'   [pushNamedAndRemoveUntil]   └─ Keluar akun ─▶ rute pertama
```

Rute terdaftar di `lib/main.dart`: `/`, `/home`, `/login`, `/help`, `/history`, `/profile`. Halaman Kuis/Scan/Menyusun/Hasil di-push sebagai `MaterialPageRoute` (tanpa nama, tanpa bilah navigasi bawah). FAB "Mulai scan" tersedia dari semua tab dan selalu masuk lewat Kuis (jalur utama kuis → scan → menyusun → hasil).

---

## 13. Catatan Implementasi

- **Warna literal** hanya di `lib/theme/app_tokens.dart`; satu pengecualian terdokumentasi: mark Google (`#4285F4`) di halaman Masuk. Tidak ada `Colors.*` di luar token.
- **`TextStyle` mentah** hanya di `lib/theme/`; halaman & widget selalu memakai peran `AppTokens.<role>.copyWith(...)`.
- **Mode terang saja**; tidak ada tema gelap. Semua animasi menghormati `MediaQuery.disableAnimations` (reduce motion).
- **Kejujuran data:** tanpa angka fallback dan tanpa progres palsu; konten tiruan ditandai "Demo"; empty state selalu menjelaskan langkah berikutnya.
- **Verifikasi desain yang sudah berjalan:** widget test menjaga dua CTA Start terlihat di 360×640; tanpa overflow pada 320/360/390/412; `textScale` 1.3 di layar Hasil; kontras token diuji via `test/token_contrast_test.dart`; font via `test/theme_font_test.dart`.
- **Sisa manual untuk tim:** smoke test izin kamera di perangkat nyata (dialog "Izin penggunaan foto") dan tinjauan dosen/pembimbing; aset lama `skin_girl.png` & `skin_magnifier.png` masih ada di repo (di luar cakupan migrasi, menunggu keputusan tim).
