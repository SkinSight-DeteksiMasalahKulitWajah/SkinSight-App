# SkinSight v2.0 — Rencana Implementasi Migrasi Penuh

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
> **PENTING — DILARANG COMMIT:** pengguna melarang keras semua perintah git yang mengubah state (`git add`, `commit`, `stash`, `checkout`, `branch`, `restore`). Git read-only (`status`, `diff`, `log`) boleh untuk laporan. Setiap task diakhiri **Verifikasi & Lapor**, bukan commit. Semua perubahan ditinggal di working tree.

**Goal:** Menyelesaikan seluruh sisa PRD SkinSight v2.0 (§1–§19) di codebase ini: satu sumber token, font dibundel, Beranda & Riwayat berbasis rekomendasi (tanpa skor), parser JSON tahan-rusak, komponen bersama, dan bersih dari kode mati — hingga lolos Definition of Done §15.

**Architecture:** Migrasi bertahap 6 tahap / 17 task; tiap task meninggalkan `flutter analyze` bersih + test hijau. Tema & font dulu (fondasi), lalu data/parser, lalu komponen bersama, lalu layar per zona visual PRD §9.2 (fungsional → data-driven → hangat), terakhir pembersihan.

**Tech Stack:** Flutter (Dart ≥3.3), provider, image_picker, camera. Font Plus Jakarta Sans dibundel (static TTF). Tanpa dependensi baru.

**Spec:** `docs/superpowers/specs/2026-10-17-skinsight-v2-full-migration-design.md` (acuan keputusan; PRD asli: `PRD SkinSight v2.0.md`)

## Global Constraints

- **TANPA COMMIT.** Jangan jalankan perintah git yang mengubah state. Semua perubahan di working tree.
- **Jangan sentuh:** `skinsight-figma.html`, `PRD SkinSight v2.0.md`, `PRD_SkinSight.md`, `README.md`.
- Light mode saja. Semua copy UI berbahasa Indonesia, sentence case, glosarium §9.5 ("Mulai scan" = satu nama untuk satu aksi).
- Warna: literal `Color(0x…)` hanya di `lib/theme/app_tokens.dart`. Pengecualian: mark Google di tombol Google (`skin_login_page.dart`). Target akhir: `Colors.white` pun diganti `AppTokens.surface` kecuali di dalam `app_tokens.dart`.
- Tipografi: Display 28/800/1.15 · H1 24/700/1.2 · H2 20/700/1.25 · Title 16/700/1.3 · Body 15/400/1.5 · Caption 13/400/1.4 · Button 16/700 · Eyebrow 12/600 (sentence case).
- Spacing kelipatan 8: margin 16 (12 compact), antar-section 24, antar-kartu 12, padding kartu 16. Radius: input/chip 12, kartu 16, modal 20. Shadow kartu: `primary` 6%, blur 12, offset (0,4) — mati di atas gradien.
- Gradien hanya header zona hangat (Start, Masuk, Beranda, Bantuan), maks ~25% tinggi layar, warna berbasis token dengan memudar ke `bg`. Zona fungsional (Quiz, Scan, Menyusun, Result, Riwayat, Profil): latar `bg` netral tanpa ilustrasi/painter dekoratif.
- Target sentuh ≥48×48; chip memakai `Wrap`; ikon bermakna punya `semanticLabel`; animasi menghormati *reduce motion*; teks tahan skala 1,3×.
- Setiap task berakhir: `flutter analyze` bersih + test terkait hijau. Setiap akhir tahap: `flutter test` penuh hijau + laporan singkat.

## Review Focus

1. **JSON rusak/sebagian** (tipe salah, item list campur, `rutinitas_harian` aneh) → bagian valid tetap tampil, tidak pernah layar kosong. Test ada di Task 3 & 4.
2. **Konten panjang / layar kecil / skala teks 1,3×** → tanpa overflow di 320–360. Test di Task 6 (+ test responsif lama dijaga).
3. **Riwayat/Beranda kosong atau gagal memuat** → empty/error state jujur, tanpa angka fallback palsu. Test di Task 10 & 11.
4. **Hapus item riwayat** → hilang dari Riwayat dan preview Beranda (via `revision`). Test di Task 11.
5. **JSON bukan JSON (decode gagal total)** → error state + "Coba lagi" berfungsi, bukan crash. Test di Task 4.

---

## Tahap 1 — Tema & Font

### Task 1: Bundel Font Plus Jakarta Sans + Wiring Tema

**Files:**
- Create: `assets/fonts/PlusJakartaSans-Regular.ttf`, `assets/fonts/PlusJakartaSans-SemiBold.ttf`, `assets/fonts/PlusJakartaSans-Bold.ttf`, `assets/fonts/PlusJakartaSans-ExtraBold.ttf`
- Modify: `pubspec.yaml` (tambah blok `fonts:`, hapus `google_fonts`), `lib/theme/app_theme.dart`
- Test: `test/theme_font_test.dart` (baru)

**Interfaces:**
- Produces: `const kSkinSightFontFamily = 'Plus Jakarta Sans'` (di `lib/theme/app_theme.dart`); tema default memakai keluarga font ini untuk seluruh textTheme.

- [ ] **Step 1: Unduh 4 static TTF ke `assets/fonts/`** (sumber upstream resmi, lisensi OFL — sudah diverifikasi 200 OK; `curl` sudah terpasang):

```powershell
mkdir assets\fonts -Force
curl.exe -L -o assets\fonts\PlusJakartaSans-Regular.ttf "https://raw.githubusercontent.com/tokotype/PlusJakartaSans/master/fonts/ttf/PlusJakartaSans-Regular.ttf"
curl.exe -L -o assets\fonts\PlusJakartaSans-SemiBold.ttf "https://raw.githubusercontent.com/tokotype/PlusJakartaSans/master/fonts/ttf/PlusJakartaSans-SemiBold.ttf"
curl.exe -L -o assets\fonts\PlusJakartaSans-Bold.ttf "https://raw.githubusercontent.com/tokotype/PlusJakartaSans/master/fonts/ttf/PlusJakartaSans-Bold.ttf"
curl.exe -L -o assets\fonts\PlusJakartaSans-ExtraBold.ttf "https://raw.githubusercontent.com/tokotype/PlusJakartaSans/master/fonts/ttf/PlusJakartaSans-ExtraBold.ttf"
```

Verifikasi: tiap file ±129 KB (bukan halaman HTML error).

- [ ] **Step 2: Daftarkan font di `pubspec.yaml`; hapus `google_fonts` dari dependencies:**

```yaml
  fonts:
    - family: Plus Jakarta Sans
      fonts:
        - asset: assets/fonts/PlusJakartaSans-Regular.ttf
          weight: 400
        - asset: assets/fonts/PlusJakartaSans-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/PlusJakartaSans-Bold.ttf
          weight: 700
        - asset: assets/fonts/PlusJakartaSans-ExtraBold.ttf
          weight: 800
```

- [ ] **Step 3: Tulis test yang gagal — `test/theme_font_test.dart`:**

```dart
test('tema memakai Plus Jakarta Sans di seluruh textTheme dan token style', () {
  final theme = buildSkinSightTheme();
  expect(theme.textTheme.bodyMedium!.fontFamily, 'Plus Jakarta Sans');
  expect(theme.textTheme.headlineMedium!.fontFamily, 'Plus Jakarta Sans');
});
testWidgets('Text dengan AppTokens.body mewarisi keluarga font tema', (tester) async {
  await tester.pumpWidget(MaterialApp(theme: buildSkinSightTheme(),
    home: const Text('contoh', style: AppTokens.body)));
  final rendered = tester.widget<RichText>(find.byType(RichText));
  expect(rendered.text.style?.fontFamily, 'Plus Jakarta Sans');
});
```

- [ ] **Step 4: Jalankan — pastikan GAGAL** (family masih dari google_fonts / null): `flutter test test/theme_font_test.dart`

- [ ] **Step 5: Ubah `lib/theme/app_theme.dart`:** hapus `import 'package:google_fonts/google_fonts.dart'`; perkenalkan `const kSkinSightFontFamily = 'Plus Jakarta Sans';`; base = `ThemeData(useMaterial3: true)`; hapus baris `GoogleFonts.plusJakartaSansTextTheme(...)`; pada hasil akhir tema, pastikan keluarga font terpasang di semua slot textTheme (mis. `textTheme: <hasil copyWith>.apply(fontFamily: kSkinSightFontFamily)`); perbaiki `labelLarge` menjadi `const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)` (tanpa warna mentah; warna datang dari tema tombol). Tambahkan `fontFamily: kSkinSightFontFamily` pada TextStyle mentah di `filledButtonTheme`/`outlinedButtonTheme`/`inputDecorationTheme` bila perlu agar merge aman.

- [ ] **Step 6: Jalankan test — pastikan LULUS:** `flutter test test/theme_font_test.dart` lalu `flutter analyze` (harus bersih; error `google_fonts` yang tersisa = ada pemakai lain — beresi).

- [ ] **Step 7: Verifikasi & Lapor** (tanpa commit): laporkan ukuran 4 file font, hasil analyze + test.

### Task 2: Token Bersih + Test Kontras

**Files:**
- Modify: `lib/theme/app_tokens.dart`
- Test: `test/token_contrast_test.dart` (baru)

**Interfaces:**
- Produces: `AppTokens.warmGradient` (LinearGradient token: `surfaceWarm` → `bg`, topCenter→bottomCenter) untuk header zona hangat; `card()` tetap seperti sekarang (§10.5).
- Menghapus: `primaryGradient`, `primarySoftGradient`, `buttonShadow`, `cardShadowSoft`. Alias legacy **belum** dihapus (masih dipakai layar; dihapus di Task 17 setelah migrasi).

- [ ] **Step 1: Tulis test yang gagal — `test/token_contrast_test.dart`** (hitung rasio WCAG dari nilai token; utilitas hitung relative luminance di file test):

```dart
double contrast(Color a, Color b); // rumus WCAG; tulis util kecil di test
test('pasangan teks penting memenuhi kontras §10.3', () {
  expect(contrast(AppTokens.primary, AppTokens.surface), greaterThanOrEqualTo(4.5));
  expect(contrast(AppTokens.inkSecondary, AppTokens.surface), greaterThanOrEqualTo(4.5));
  expect(contrast(AppTokens.warnChipText, AppTokens.warnChipBg), greaterThanOrEqualTo(4.5));
  expect(contrast(AppTokens.ink, AppTokens.bg), greaterThanOrEqualTo(4.5));
});
test('primarySoft DILARANG untuk teks kecil (dokumentasi aturan)', () {
  expect(contrast(AppTokens.primarySoft, AppTokens.surface), lessThan(4.5));
});
test('warmGradient memudar dari surfaceWarm ke bg', () {
  expect(AppTokens.warmGradient.colors.first, AppTokens.surfaceWarm);
  expect(AppTokens.warmGradient.colors.last, AppTokens.bg);
});
```

- [ ] **Step 2: Jalankan — GAGAL** (`warmGradient` belum ada): `flutter test test/token_contrast_test.dart`

- [ ] **Step 3: Edit `lib/theme/app_tokens.dart`:** hapus blok "Profesional: gradient + shadow" (`primaryGradient`, `primarySoftGradient`, `get buttonShadow`, `get cardShadowSoft`); tambah:

```dart
static const LinearGradient warmGradient = LinearGradient(
  begin: Alignment.topCenter, end: Alignment.bottomCenter,
  colors: [surfaceWarm, bg],
);
```

- [ ] **Step 4: Jalankan — LULUS**, lalu `flutter analyze`. Pemakai lama `buttonShadow`/`primaryGradient` (start/login/home/history/help) akan ERROR — itu wajar; untuk sementara ganti pemakaiannya dengan `AppTokens.card()`-nya / `primary` polos di file yang error agar tetap kompilabel di task ini (penghalusan visual menyusul di Tahap 3–5).
- [ ] **Step 5: `flutter test` (suite penuh) — hijau.** (Kontras & font beres; suite lama masih lolos.)
- [ ] **Step 6: Verifikasi & Lapor.**

---

## Tahap 2 — Data & Parser

### Task 3: Parser Tahan-Rusak (`skin_recommendation.dart`)

**Files:**
- Modify: `lib/models/skin_recommendation.dart`
- Test: `test/recommendation_contract_test.dart` (perluas)

**Interfaces:**
- Produces: `SkinRecommendation.fromJsonString(String)` — decode + map; melempar `FormatException` HANYA bila string bukan JSON objek (`'bukan json'`, `'[1,2]'`, `'null'`). `SkinRecommendation.fromJson(Map<String, Object?>)` **tidak pernah melempar**; `tipe_kulit` hilang/non-string/enum tak dikenal → `tipeKulit = 'Belum dapat ditentukan'`, `tipeResolved = false`. Salvage per-item: satu item rusak tidak membuang seluruh daftar. Batas tetap: penjelasan 280, `fungsi` 120, langkah 100, cap 5/5/6/6/4/3. `toJson` dipertahankan.

- [ ] **Step 1: Tulis test baru yang GAGAL di `test/recommendation_contract_test.dart`:**

```dart
test('fromJsonString menolak non-JSON objek', () {
  expect(() => SkinRecommendation.fromJsonString('bukan json'), throwsFormatException);
  expect(() => SkinRecommendation.fromJsonString('[1,2]'), throwsFormatException);
});
test('fromJson tidak pernah melempar untuk field kacau', () {
  final r = SkinRecommendation.fromJson(const {
    'schema_version': 123, 'tipe_kulit': 123, 'penjelasan_singkat': 456,
    'zat_aktif_rekomendasi': 'BUKAN_LIST', 'zat_aktif_dihindari': {'a': 1},
    'rutinitas_harian': 'RUSAK', 'perawatan_tambahan': 9, 'sumber_referensi': 'x',
  });
  expect(r.tipeKulit, 'Belum dapat ditentukan');
  expect(r.tipeResolved, isFalse);
  expect(r.rekomendasi, isEmpty); expect(r.rutinPagi, isEmpty); expect(r.referensi, isEmpty);
});
test('satu item rusak tidak membuang seluruh daftar', () {
  final r = SkinRecommendation.fromJson(const {
    'tipe_kulit': 'Normal',
    'zat_aktif_rekomendasi': [
      {'nama': 'Niacinamide', 'fungsi': 'menenangkan'},
      {'fungsi': 'tanpa nama'},
      'bukan map',
    ],
  });
  expect(r.rekomendasi, hasLength(1));
  expect(r.rekomendasi.first.nama, 'Niacinamide');
});
test('tipe_kulit hilang tetap menghasilkan objek (bukan lempar)', () {
  final r = SkinRecommendation.fromJson(const {'schema_version': '1.0'});
  expect(r.tipeKulit, 'Belum dapat ditentukan');
});
```

(Sesuaikan test lama yang mengharapkan `FormatException('tipe_kulit wajib')` → kini objek "Belum dapat ditentukan".)

- [ ] **Step 2: Jalankan — GAGAL:** `flutter test test/recommendation_contract_test.dart`

- [ ] **Step 3: Implementasi di `lib/models/skin_recommendation.dart`:**
  - Helper privat: `static String _str(Object? v)` (string? trim : ''), `static List<Object?> _list(Object? v)` (List? : const []), `static Map<Object?, Object?> _mapOf(Object? v)` (Map? : const {}).
  - `fromJsonString`: `final decoded = jsonDecode(raw); if (decoded is! Map) throw const FormatException('JSON bukan objek'); return fromJson(decoded.map((k, v) => MapEntry(k.toString(), v)));` — tangkap `FormatException` dari jsonDecode & lempar ulang dengan pesan yang sama tipenya.
  - Ganti semua `as String?` / `as List?` dengan helper; `tipe_kulit` pakai `_str`; hapus throw `'tipe_kulit wajib'`.
  - Item list: loop manual dengan `try { … } catch (_) { /* lewati item */ }` per item (aktif & referensi).
  - `_clipSteps`: hapus parameter `min`.

- [ ] **Step 4: Jalankan — LULUS:** `flutter test test/recommendation_contract_test.dart` (termasuk kasus lama: pendek/normal/panjang/rusak + cap).
- [ ] **Step 5: `flutter analyze` bersih; `flutter test` penuh hijau** (Repo mock saat ini mengirim Map — masih kompilabel karena `fromJson` dipertahankan).
- [ ] **Step 6: Verifikasi & Lapor.**

### Task 4: Mock Repo → String JSON + Seam & State `SkinAnalysisPage`

**Files:**
- Modify: `lib/data/mock_recommendation_repository.dart`, `lib/pages/skin_analysis_page.dart`, `lib/theme/app_copy.dart` (tambah `errInvalidData`)
- Test: `test/analysis_page_test.dart` (baru)

**Interfaces:**
- Consumes: `SkinRecommendation.fromJsonString` (Task 3).
- Produces: `MockRecommendationRepository.fetchRecommendation({List<int>? quizAnswers, String scenario = 'normal', Duration? delayOverride})` — sumber data = **string JSON mentah**; skenario: `normal`, `pendek`, `panjang`, `rusak` (Map valid tapi field kacau), `tidak-valid` (bukan JSON), `timeout`. Latensi/timeout/maxRetry tetap seperti sekarang.
- Produces: `SkinAnalysisPage({..., MockRecommendationRepository? repository})` — seam test (null → `MockRecommendationRepository.instance` di `initState`).
- Produces: `AppCopy.errInvalidData = 'Hasil tidak dapat dibaca. Coba lagi atau ulangi foto.'`

- [ ] **Step 1: Tulis test GAGAL — `test/analysis_page_test.dart`** (pump `MaterialApp(home: SkinAnalysisPage(selfieBytes: Uint8List(8), repository: fakeKereta..., scenario: X))` dengan `delayOverride` pendek; gunakan repository nyata + scenario, delay kecil):

```dart
testWidgets('sukses menampilkan Result', ...);        // scenario normal, delayOverride 1ms → pumpAndSettle → find hasil
testWidgets('timeout menampilkan error + Coba lagi', ...);   // scenario timeout → find.text(AppCopy.ctaCobaLagi)
testWidgets('batas retry 3x tercapai', ...);          // tap Coba lagi 3x → find.text(AppCopy.errRetryLimit)
testWidgets('decode gagal menampilkan pesan data tidak terbaca', ...); // scenario tidak-valid → find.text(AppCopy.errInvalidData)
```

- [ ] **Step 2: Jalankan — GAGAL** (seam & skenario belum ada).
- [ ] **Step 3: Implementasi:**
  - Mock repo: ganti semua Map literal dengan `static const Map<String, String> _payloads = {...}` berisi string JSON (raw triple-quote). `fetchRecommendation` → mekanisme latensi/timeout yang ada dipertahankan, lalu `SkinRecommendation.fromJsonString(raw)`.
  - `skin_analysis_page.dart`: tambah field `repository`; `initState`: `_repo = widget.repository ?? MockRecommendationRepository.instance`; `_fetch` memakai `_repo`; pemetaan error: `TimeoutException` → `AppCopy.errTimeout`; `FormatException` → `AppCopy.errInvalidData`; lain-lain → `AppCopy.errTimeout`.
  - `app_copy.dart`: tambah konstanta di atas.
- [ ] **Step 4: Jalankan — LULUS:** `flutter test test/analysis_page_test.dart` + `flutter test test/recommendation_contract_test.dart`.
- [ ] **Step 5: `flutter analyze` bersih; `flutter test` penuh hijau.**
- [ ] **Step 6: Verifikasi & Lapor.** (Akhir Tahap 2: demo 6 skenario + laporan.)

---

## Tahap 3 — Komponen Bersama + Layar Fungsional

### Task 5: `lib/widgets/` — 9 Komponen Bersama

**Files:**
- Create: `lib/widgets/screen_header.dart`, `lib/widgets/sight_bottom_nav.dart`, `lib/widgets/section_card.dart`, `lib/widgets/step_list.dart`, `lib/widgets/avoid_chip.dart`, `lib/widgets/demo_badge.dart`, `lib/widgets/empty_state.dart`, `lib/widgets/error_state.dart`, `lib/widgets/status_notice.dart`
- Test: `test/widgets_smoke_test.dart` (baru)

**Interfaces (dipakai Task 6–16):**

```dart
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.onBack, this.actions = const [], this.showBack = true});
  final String title; final VoidCallback? onBack; final List<Widget> actions; final bool showBack;
} // back = 48×48 lingkaran, Icons.arrow_back_rounded, semanticLabel 'Kembali', onBack ?? Navigator.maybePop; title = AppTokens.h2 (20/700)

class SightBottomNav extends StatelessWidget {
  const SightBottomNav({super.key, required this.active});
  final SightTab active; // enum SightTab { beranda, riwayat, bantuan, profil }
} // 4 item berlabel (Icons.home_rounded/history_rounded/help_outline_rounded/person_outline_rounded; aktif = primary) + FAB tengah 'Mulai scan' (primary, semanticLabel) → push Quiz
  // navigasi: beranda → Navigator.popUntil(context, ModalRoute.withName('/home'));
  // lain → Navigator.pushNamedAndRemoveUntil(context, route, ModalRoute.withName('/home'))
  // rute: '/history', '/help', '/profile'

class SectionCard extends StatelessWidget { // surface, border, r16, AppTokens.card(), padding 16 default
  const SectionCard({super.key, required this.child, this.padding = const EdgeInsets.all(AppLayout.cardPadding), this.shadow = true});
}
class StepList extends StatelessWidget { const StepList({super.key, required this.steps}); } // langkah bernomor: lingkaran primarySoft + nomor putih kecil, teks AppTokens.body, jarak 12
class AvoidChip extends StatelessWidget { const AvoidChip({super.key, required this.label}); } // Wrap-friendly: bg warnChipBg, teks warnChipText, Icons.warning_amber_rounded 18, r12, padding h12 v8
class DemoBadge extends StatelessWidget { const DemoBadge({super.key}); } // teks AppCopy.demoBadge, caption, successSoft bg, primarySoft teks, r12
class EmptyState extends StatelessWidget { const EmptyState({super.key, required this.icon, required this.title, this.message, this.action}); }
class ErrorState extends StatelessWidget { const ErrorState({super.key, required this.message, this.onRetry, this.secondaryLabel, this.onSecondary}); } // ikon cloud_off_rounded, AppCopy.ctaCobaLagi sebagai label default onRetry bila null? — tidak: onRetry null → tombol disembunyikan
class StatusNotice extends StatelessWidget { const StatusNotice({super.key, required this.message, this.icon = Icons.info_outline_rounded, this.tone = StatusTone.info}); } // enum StatusTone { info, warn, error } — warn=warnChip*, error=danger, info=info/successSoft
```

- [ ] **Step 1: Tulis `test/widgets_smoke_test.dart` (GAGAL):** render tiap komponen di `MaterialApp`; assert: `ScreenHeader` menampilkan judul + tombol 'Kembali' dengan tooltip/semantics; `AvoidChip` menampilkan ikon + teks; `SightBottomNav(active: beranda)` menampilkan 4 label + FAB 'Mulai scan'; `EmptyState` menampilkan judul+CTA bila `action` diberi.
- [ ] **Step 2: Jalankan — GAGAL.** `flutter test test/widgets_smoke_test.dart`
- [ ] **Step 3: Implementasi 9 file** sesuai kontrak di atas (token-only; tanpa `Color(0x` literal; `Colors.white` → `AppTokens.surface`).
- [ ] **Step 4: Jalankan — LULUS.** Lalu `flutter analyze`.
- [ ] **Step 5: Verifikasi & Lapor.**

### Task 6: Result — Migrasi ke Komponen + Polish

**Files:**
- Modify: `lib/pages/skin_result_page.dart`, `lib/main.dart` (hapus route `'/result'`)
- Test: `test/scan_result_responsive_test.dart` (sesuaikan) + kasus baru

**Interfaces:**
- Consumes: komponen Task 5; `ErrorState` tidak dipakai di sini; `AvoidChip`, `StepList`, `SectionCard`, `DemoBadge`, `ScreenHeader`.

- [ ] **Step 1: Test yang GAGAL ditambahkan ke `test/scan_result_responsive_test.dart`:**
  - `Result @360×640 textScale 1.3 tanpa overflow` — pump dengan `MediaQuery(textScaler: TextScaler.linear(1.3))`, assert `tester.takeException() == null` dan tidak ada `RenderFlex overflow` (pola sama dengan test responsif yang ada).
  - `chip hindari memuat ikon + teks` — `find.byIcon(Icons.warning_amber_rounded)` untuk tiap chip.
  - `badge Demo tampil di header`.
- [ ] **Step 2: Jalankan — GAGAL.**
- [ ] **Step 3: Refactor `skin_result_page.dart`:** ganti header privat → `ScreenHeader`; kartu → `SectionCard` (+`shadow: false` bila di atas gradien — di Result latar netral, jadi shadow normal); rutinitas → `StepList`; hindari → `Wrap` + `AvoidChip`; tambah `DemoBadge`; bottom CTA sudah ada → pastikan `SafeArea` + `FilledButton`/`OutlinedButton` tema; hapus semua salinan privat yang tergantikan; `Colors.white`→token. Hapus route `'/result'` dari `main.dart`.
- [ ] **Step 4: Jalankan — LULUS:** `flutter test test/scan_result_responsive_test.dart` + seluruh suite lama yang menyentuh Result.
- [ ] **Step 5: grep file ini: `Color(0x` = 0 (selain allowlist) & tidak ada `TextStyle(` baru di luar token.** `flutter analyze`.
- [ ] **Step 6: Verifikasi & Lapor.**

### Task 7: Quiz — Migrasi + Kembali Antar-Soal + Eyebrow

**Files:**
- Modify: `lib/pages/skin_quiz_page.dart`
- Test: `test/quiz_navigation_test.dart` (perluas), `test/quiz_breeze_test.dart` (sesuaikan nama/apapun yang usang)

**Interfaces:**
- Produces: top bar = eyebrow **"Langkah n dari 5"** (`AppTokens.eyebrow`, sentence case) + `LinearProgressIndicator` (`primarySoft`); tombol kembali (`showBack`-style chevron khusus quiz, 48×48) tampil saat `n > 1` → soal sebelumnya dengan jawaban terpilih tetap tampil; tombol tutup (X) tetap membatalkan kuis.

- [ ] **Step 1: Test GAGAL di `test/quiz_navigation_test.dart`:**
  - `label progres berbunyi 'Langkah 1 dari 5'` lalu maju → `'Langkah 2 dari 5'`.
  - `jawaban tersimpan saat mundur/maju`: jawab soal 1 → Lanjut → tap kembali → opsi terpilih soal 1 masih tercentang → Lanjut lagi → soal 2.
  - `tombol kembali tidak tampil di soal 1`.
- [ ] **Step 2: Jalankan — GAGAL.**
- [ ] **Step 3: Refactor `skin_quiz_page.dart`:** hapus `_BreezeBlobs` (zona fungsional); top bar baru (eyebrow + progress + tombol kembali + tutup); warna → token (`primarySoft` progress, terpilih: border `primary` + latar `successSoft`); aksi `Lanjut`/`Selesai` sesuai FR-05; animasi transisi (bila ada) memakai durasi 150–250 ms dan di-skip bila `MediaQuery.of(context).disableAnimations`.
- [ ] **Step 4: Jalankan — LULUS:** file quiz + suite penuh (test lama yang memeriksa teks `n/5` disesuaikan).
- [ ] **Step 5: grep `Color(0x` di file quiz = 0; `flutter analyze` bersih.**
- [ ] **Step 6: Verifikasi & Lapor.**

### Task 8: Scan — Token-only + Buang Dekorasi

**Files:**
- Modify: `lib/pages/skin_scan_page.dart`
- Test: tidak ada test khusus kamera (plugin) — verifikasi statis + suite penuh.

- [ ] **Step 1: Migrasi:** semua warna → token (mapping dokumen §4); hapus `_ScanBackgroundPainter` dan pemakaiannya (zona fungsional, latar `bg`); bingkai kamera → `surface`/`border` (radius r20/r16); tombol kontrol → token; pastikan copy error memakai `AppCopy` (`errCameraDenied`, `errNoCamera`, `errFileTooBig`, `lightHint`); `safeArea` untuk kontrol bawah; target sentuh 48+.
- [ ] **Step 2: grep `Color(0x` di file = 0; `flutter analyze` bersih; `flutter test` penuh hijau.**
- [ ] **Step 3: Verifikasi & Lapor (sebutkan area yang butuh smoke manual di perangkat: izin ditolak, >10 MB, kamera tak tersedia).**

### Task 9: Menyusun Rekomendasi — Migrasi Body ke Komponen

**Files:**
- Modify: `lib/pages/skin_analysis_page.dart`
- Test: `test/analysis_page_test.dart` tetap hijau (regresi).

- [ ] **Step 1: Refactor:** body loading/error memakai komponen bersama (`ErrorState` dengan `onRetry`/`onSecondary` menggantikan `_ErrorBody`; skeleton boleh tetap privat tapi token-only); pastikan `bg` netral; `SafeArea`.
- [ ] **Step 2: `flutter test test/analysis_page_test.dart` + suite penuh hijau; grep `Color(0x` di file = 0; `flutter analyze` bersih.**
- [ ] **Step 3: Verifikasi & Lapor.** (Akhir Tahap 3: laporan + suite penuh.)

---

## Tahap 4 — Beranda → Data → Riwayat

### Task 10: Beranda Redesain (Tanpa Skor) + Pecah File

**Files:**
- Modify: `lib/pages/skin_home_page.dart` (jadi shell tipis)
- Create: `lib/pages/home/home_warm_header.dart`, `lib/pages/home/home_latest_card.dart`, `lib/pages/home/home_history_preview.dart`
- Test: `test/dashboard_history_test.dart` (tulis ulang)

**Interfaces:**
- Consumes: `SkinHistoryRepository` (`fetchLatest`, `fetchHistory`, `revision`), `SkinAnalysis.recommendation` (model lama masih dipakai di task ini — `recommendation` sudah ada), `SightBottomNav`, `EmptyState`, `ErrorState`, `DemoBadge`.

- [ ] **Step 1: Tulis ulang `test/dashboard_history_test.dart` (GAGAL):**
  - `repo kosong → empty state 'Belum ada hasil' + CTA 'Mulai scan' (tanpa angka 82/68/34)`.
  - `ada hasil tersimpan → kartu hasil terakhir menampilkan tipe kulit + badge Demo + tombol 'Lihat hasil'`; tap → Result mode baca.
  - `preview riwayat menampilkan maksimal 3 baris` + `revision: setelah save baru, daftar ikut berubah` (pump ulang / notify).
- [ ] **Step 2: Jalankan — GAGAL.**
- [ ] **Step 3: Implementasi:**
  - `home_warm_header.dart`: `HomeWarmHeader(greetingName, photoBytes)` — latar `AppTokens.warmGradient` tinggi = 25% dari tinggi konten + sisanya `bg` (Stack/Container), avatar + sapaan + akses ke Profil; `shadow: false` untuk kartu di atas gradien.
  - `home_latest_card.dart`: `HomeLatestCard(analysis?, onView)` — tipe = `analysis.recommendation!.tipeKulit`, tanggal ringkas, `DemoBadge`, tombol "Lihat hasil"; null → `EmptyState(icon: face_retouching_natural?, title: 'Belum ada hasil', message: 'Mulai scan untuk mendapat rekomendasi pertamamu.', action: CTA)`.
  - `home_history_preview.dart`: `HomeHistoryPreview(items, onSeeAll, onTap)` — maks 3 baris (tipe + tanggal), "Lihat semua" → pindah tab Riwayat.
  - `skin_home_page.dart`: shell ListView: header, tombol "Mulai scan" (FilledButton, area jempol — tepat di atas konten, satu-satunya CTA primer), kartu hasil terakhir, preview, `SightBottomNav(active: beranda)`. Hapus: `_ScanCard`, `_HealthBadge`, `_Metric`, `_HistoryCard`/`_Bars`, fallback angka, notifikasi palsu, `cat_happy`/`skin_analyze_title` usage (judul jadi `Text`), painter yang tak terpakai. Dengar `revision` untuk refresh.
- [ ] **Step 4: Jalankan — LULUS:** `flutter test test/dashboard_history_test.dart` + suite penuh (test lain yang menyentuh home disesuaikan bila perlu).
- [ ] **Step 5: grep `Color(0x` di file home = 0; `flutter analyze` bersih.**
- [ ] **Step 6: Verifikasi & Lapor.**

### Task 11: Data Layer v2.0 + Riwayat Redesain

**Files:**
- Modify: `lib/models/skin_analysis.dart` (sederhanakan), `lib/data/skin_history_repository.dart` (seed v2.0, hapus `saveLatest`/`saveAnalysis` bila tak terpakai), `lib/pages/skin_history_page.dart` (redesain), `lib/pages/skin_result_page.dart` (fallback legacy)
- Delete: `lib/data/quiz_scoring.dart`, `test/quiz_scoring_test.dart`
- Test: `test/history_page_test.dart` (tulis ulang), `test/dashboard_history_test.dart` (sesuaikan fixture)

**Interfaces:**
- Produces: `SkinAnalysis({required String id, required DateTime analyzedAt, SkinRecommendation? recommendation, Uint8List? selfieBytes})` — field skor/title/skinType/metrik DIHAPUS.
- Produces: `SkinHistoryRepository.saveRecommendation(SkinRecommendation rec, {Uint8List? selfieBytes, DateTime? analyzedAt})` → `Future<SkinAnalysis>` (record baru di paling atas + `revision++`); `fetchHistory({DateTime? date, bool newestFirst=true})`, `fetchLatest(int count)`, `deleteAnalysis(String id)` dipertahankan; seed = 3 rekomendasi (id `scan-2026-10-03` normal, `scan-2026-09-27` pendek, `scan-2026-09-14` panjang).
- Consumes: `SkinRecommendation.fromJsonString` untuk seed.

- [ ] **Step 1: Tulis ulang `test/history_page_test.dart` (GAGAL):**
  - baris menampilkan tipe kulit + tanggal; **tidak ada** angka skor/"Minyak x%".
  - `hapus item → konfirmasi → baris hilang` (dan `revision` naik).
  - `filter tanggal & urutan Terbaru/Terlama berfungsi`.
  - `empty state memuat CTA 'Mulai scan'`.
- [ ] **Step 2: Jalankan — GAGAL.** (Fixture test lama juga akan gagal kompilasi — itu bagian dari kerja.)
- [ ] **Step 3: Implementasi:**
  - `skin_analysis.dart`: sederhanakan per Interfaces; hapus `copyWith` bila tak terpakai.
  - Repo: seed via `SkinRecommendation.fromJsonString` (3 JSON ringkas inline); `saveRecommendation` sesuai; hapus `saveLatest`; hapus `saveAnalysis` bila grep menunjukkan nol pemakai; hapus file `quiz_scoring.dart` + testnya.
  - `skin_history_page.dart`: `ScreenHeader('Riwayat')` + kontrol sort/filter yang ada; baris = `SectionCard`-ish list row (tipe `AppTokens.title`, tanggal `caption`, chevron; swatch kecil `successSoft` boleh sebagai pengganti badge skor); tap → Result `archived: true`; ikon hapus + dialog konfirmasi (`danger`); `FutureBuilder` dengan cabang `snapshot.hasError` → `ErrorState`; empty → `EmptyState` + CTA; `SightBottomNav(active: riwayat)`; tanpa painter dekoratif.
  - `skin_result_page.dart`: hapus jalur sintesis legacy (`'1.0-legacy'`); `analysis.recommendation == null` → `_EmptyBody` yang sudah ada.
- [ ] **Step 4: Jalankan — LULUS:** history + dashboard + result tests; `flutter test` penuh.
- [ ] **Step 5: grep `Color(0x` di kedua file = 0; `flutter analyze` bersih.**
- [ ] **Step 6: Verifikasi & Lapor.**

### Task 12: Uji Alur Quiz → Analysis → Result → Riwayat

**Files:**
- Test: `test/flow_quiz_to_history_test.dart` (baru)

- [ ] **Step 1: Tulis test (GAGAL karena perlu penyesuaian navigasi test):** rangkaian dalam satu file test:
  1. Pump Quiz via `MaterialApp(routes)` → jawab 5 soal (pakai tombol kembali sekali untuk cek retensi) → selesai → pastikan `SkinScanPage` tampil (leg kamera tidak dijalankan — bypass kamera didokumentasikan sebagai batasan plugin).
  2. Pump `SkinAnalysisPage(selfieBytes: Uint8List(8), repository: …, scenario: 'normal')` (delay 1ms) → tunggu → Result tampil (tipe kulit ada).
  3. Tap **Simpan hasil** → pump `SkinHistoryPage` → baris dengan tipe kulit tsb muncul; hapus baris → hilang.
- [ ] **Step 2: Jalankan — GAGAL** (samakan seam/nama repo; perbaiki sampai hijau).
- [ ] **Step 3: Jalankan — LULUS:** `flutter test test/flow_quiz_to_history_test.dart`; lalu `flutter test` penuh; `flutter analyze` bersih.
- [ ] **Step 4: Verifikasi & Lapor.** (Akhir Tahap 4.)

---

## Tahap 5 — Zona Hangat

### Task 13: Start — Migrasi ke Token + Zona Hangat

**Files:**
- Modify: `lib/pages/skin_start_page.dart`
- Test: `test/start_page_test.dart` (sesuaikan bila ada asumsi warna/struktur)

- [ ] **Step 1: Migrasi sesuai spesifikasi dokumen §5.1:** latar = `AppTokens.warmGradient` (maks 25%) di atas `bg`; tombol "Mulai" = `FilledButton` tema (flat `primary`); link "Masuk" = teks `primary`; judul: buang shader gradien lama (pakai `ink`/`primary` polos, gaya `display`); hapus pemakaian `start_background.png`; hero = `start_avatar.png` saja; painter dekor disederhanakan ke palet token atau dihapus (target: satu elemen visual khas). Dua CTA terlihat tanpa scroll di 360×640 (FR-01 — pastikan test).
- [ ] **Step 2: grep `Color(0x` di file = 0; `flutter analyze` bersih; `flutter test test/start_page_test.dart` + suite hijau.**
- [ ] **Step 3: Verifikasi & Lapor.**

### Task 14: Masuk — Migrasi + Baris Usia

**Files:**
- Modify: `lib/pages/skin_login_page.dart`, `lib/theme/app_copy.dart` (tambah `ageNotice`)
- Test: `test/login_page_test.dart` (perluas)

**Interfaces:**
- Produces: `AppCopy.ageNotice = 'Dengan mendaftar, kamu menyatakan berusia 17 tahun atau lebih.'` — tampil hanya pada mode **Daftar**.

- [ ] **Step 1: Tambah test GAGAL:** di mode Daftar, `find.text(AppCopy.ageNotice)` ada; di mode Masuk, tidak ada. (Plus test validasi lama tetap hijau.)
- [ ] **Step 2: Implementasi:** token-only (field r12 dari tema; error `danger`); tombol utama flat `primary`; tombol Google tetap nonaktif + "Segera hadir" (mark Google = satu-satunya warna non-token yang diizinkan); baris usia di mode Daftar (caption); animasi switcher 150–250 ms + hormati `disableAnimations`; hapus pemakaian `start_background.png`; hero avatar satu.
- [ ] **Step 3: grep `Color(0x` di file = hanya mark Google; `flutter analyze` bersih; `flutter test` file + suite hijau.**
- [ ] **Step 4: Verifikasi & Lapor.**

### Task 15: Bantuan — Migrasi + Versi 2.0.0

**Files:**
- Modify: `lib/pages/skin_help_page.dart`, `lib/theme/app_copy.dart` (tambah `appVersion`)
- Test: `test/help_page_test.dart` (sesuaikan)

**Interfaces:**
- Produces: `AppCopy.appVersion = 'Versi 2.0.0'` — menggantikan string "Versi 1.1.0" (saat ini di sekitar baris 551).

- [ ] **Step 1: Test GAGAL:** about section menampilkan `AppCopy.appVersion` dan tidak ada teks "Versi 1.1.0".
- [ ] **Step 2: Implementasi:** latar zona hangat (`warmGradient` maks 25% di atas `bg`); semua warna → token (mapping dokumen §4); accordion → `SectionCard` (r16 border token); teks "Versi 1.1.0" → `AppCopy.appVersion`; painter/latar sky lama dihapus; `SightBottomNav(active: bantuan)`.
- [ ] **Step 3: grep `Color(0x` di file = 0; `flutter analyze` bersih; test file + suite hijau.**
- [ ] **Step 4: Verifikasi & Lapor.**

### Task 16: Profil — Migrasi + Badge Demo

**Files:**
- Modify: `lib/pages/skin_profile_page.dart`
- Test: `test/profile_page_test.dart` (perluas)

- [ ] **Step 1: Test GAGAL:** badge `Demo` tampil (data dummy); tombol "Keluar akun" bergaya danger outline (assert warna `foregroundColor` = `AppTokens.danger` via widget lookup); gradient sky lama tidak ada (zona fungsional → `bg`).
- [ ] **Step 2: Implementasi:** token-only; hapus gradient sky (latar `bg`); header → `ScreenHeader('Profil')`-pola; dialog edit/validasi/sandi tetap; `DemoBadge` di bagian identitas; `SightBottomNav(active: profil)`.
- [ ] **Step 3: grep `Color(0x` di file = 0; `flutter analyze` bersih; test file + suite hijau.**
- [ ] **Step 4: Verifikasi & Lapor.** (Akhir Tahap 5.)

---

## Tahap 6 — Bersih-bersih & DoD

### Task 17: Hapus Alias Legacy, Kode Mati, Aset; Sweep Akhir

**Files:**
- Modify: `lib/theme/app_tokens.dart` (hapus blok alias legacy), `pubspec.yaml` (hapus `flutter_animate`)
- Delete: `cat_happy.png`, `skin_analyze_title.png`, `skin_background/start_background.png` (bila kini tak terpakai), `bubbles.png`, `city_background.png`, `clouds.png`, `description_sticker.png`, `hero_decor.png`, `leaves_flowers.png`, `sparkles.png`, `try_now_sticker.png` — **verifikasi nol referensi via grep sebelum hapus tiap file**
- Test: seluruh suite

- [ ] **Step 1: Hapus alias legacy** dari `app_tokens.dart` setelah `grep` membuktikan nol pemakaian (`teal|deepTeal|navy|cream|pageBg|cardBorder|muted|coral|orange|sky`).
- [ ] **Step 2: Hapus dependensi `flutter_animate`** dari pubspec; `flutter analyze` memastikan tak ada import.
- [ ] **Step 3: Hapus aset tak terpakai** (grep per nama file dulu; `start_background`/`skin_analyze_title`/`cat_happy` diperkirakan sudah bebas sejak Task 10/13/14).
- [ ] **Step 4: Sweep akhir (bukti DoD):**
  - `Color(0x` di `lib/` → hanya `app_tokens.dart` (+ pengecualian terdokumentasi mark Google).
  - `Colors.` di `lib/` → hanya di `app_tokens.dart`.
  - `TextStyle(` di `lib/` → hanya di `lib/theme/` (+ `widgets/` bila memakai token).
  - Tidak ada string "1.1" tersisa di `lib/`.
  - `flutter analyze` bersih; `flutter test` penuh hijau.
- [ ] **Step 5: Jalankan daftar DoD §15 satu per satu** dan tulis hasilnya di laporan akhir (termasuk item manual: kontras via test Task 2; font via test Task 1; 360×640 via test responsif; disclaimer/consent via test/hasil grep copy).
- [ ] **Step 6: Laporan akhir ke pengguna** (ringkasan per tahap + daftar file berubah + sisa item manual/bekas untuk tim). **Tanpa commit.**

---

## Catatan Deviasi dari Dokumen Desain

- Penyederhanaan `SkinAnalysis` + seed v2.0 + `FutureBuilder` error + penghapusan `quiz_scoring` dipindah dari Tahap 2 ke **Tahap 4 (Task 11)**: Beranda & Riwayat adalah satu-satunya pemakai field skor, jadi perubahan model harus berjalan bersama redesain keduanya agar setiap tahap tetap hijau. Tabel tahap di dokumen desain sudah diselaraskan.
- Uji alur (Task 12) mem-bypass leg kamera (tidak dapat dikemudikan di widget test); leg Scan dijaga oleh copy/guard sendiri + smoke manual.
