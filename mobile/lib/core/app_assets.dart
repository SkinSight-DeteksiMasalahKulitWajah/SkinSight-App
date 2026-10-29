import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Satu-satunya tempat path aset gambar.
///
/// Semua aset berada di folder `assets/` di root project dan didaftarkan di
/// `pubspec.yaml` per folder (`assets/photos/`, `assets/3d/`). Di Flutter Web,
/// aset dengan key `assets/3d/x.png` dilayani di URL `assets/assets/3d/x.png`.
abstract final class AppAssets {
  static const _photos = 'assets/photos';
  static const _3d = 'assets/3d';

  // ── Foto ───────────────────────────────────────────────────────────────
  /// Potret layar pembuka (1200×2400, subjek di kanan, latar putih lembut).
  static const heroPortrait = '$_photos/hero_portrait.jpg';

  /// Potongan subjek dari [heroPortrait] (ukuran & posisi identik, latar
  /// transparan) — dilapis di atas aloe agar daun berada di belakang wajah.
  static const heroSubject = '$_photos/hero_subject.webp';

  /// Potret wajah 3:4 untuk ilustrasi pemindaian (Home & etalase analisis).
  static const scanPortrait = '$_photos/scan_portrait.jpg';

  // ── Ilustrasi 3D (render Blender, latar transparan, ±768 px) ──────────
  /// Rumpun lidah buaya — aksen botani di seluruh aplikasi.
  static const aloe3d = '$_3d/aloe.png';

  /// Botol serum kaca + daun + tetesan, di atas podium.
  static const serum3d = '$_3d/serum.png';

  /// Ponsel kaca dengan cincin pindai wajah & kaca pembesar.
  static const scan3d = '$_3d/scan.png';

  /// Grafik batang kaca yang naik dengan tunas daun.
  static const journey3d = '$_3d/journey.png';

  /// Kalender dengan lencana centang.
  static const checkin3d = '$_3d/checkin.png';

  /// Avatar pengguna default (kepala + bahu, sage).
  static const avatar3d = '$_3d/avatar.png';

  /// Bintang-bintang perayaan (pencapaian, akhir periode).
  static const celebrate3d = '$_3d/celebrate.png';

  /// Gelembung percakapan (bantuan & dukungan).
  static const help3d = '$_3d/help.png';

  // ── Alias nama lama (agar pemanggil lama tetap valid) ──────────────────
  static const startAvatar = avatar3d;
  static const catHappy = celebrate3d;
  static const skinGirl = serum3d;
  static const onboarding1 = scan3d;
  static const onboarding2 = journey3d;
  static const onboarding3 = checkin3d;

  /// Aset yang harus selalu ada; diverifikasi oleh test.
  static const bundled = <String>[
    heroPortrait,
    heroSubject,
    scanPortrait,
    aloe3d,
    serum3d,
    scan3d,
    journey3d,
    checkin3d,
    avatar3d,
    celebrate3d,
    help3d,
  ];

  /// Aset yang boleh belum ada (dicek lewat manifest sebelum dimuat).
  static const optional = <String>[];

  static Future<Set<String>>? _manifest;

  /// Apakah [asset] terdaftar di AssetManifest build ini.
  /// Hasil manifest di-cache; kegagalan membaca manifest dianggap "tidak ada"
  /// agar UI jatuh ke fallback, bukan error.
  static Future<bool> exists(String asset) async {
    final manifest = _manifest ??= _loadManifest();
    return (await manifest).contains(asset);
  }

  static Future<Set<String>> _loadManifest() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      return manifest.listAssets().toSet();
    } on Object catch (error) {
      debugPrint('AssetManifest tidak dapat dibaca: $error');
      return const <String>{};
    }
  }

  @visibleForTesting
  static void resetManifestCache() => _manifest = null;
}
