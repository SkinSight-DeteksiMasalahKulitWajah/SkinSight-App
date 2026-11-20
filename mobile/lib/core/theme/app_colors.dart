import 'package:flutter/painting.dart';

/// Palet SkinSight: satu-satunya tempat nilai warna heksadesimal.
///
/// `ThemeData`/`ColorScheme` (lihat `skin_theme.dart`) dibangun dari nilai di
/// sini, dan widget membaca warna lewat tema atau kelas ini, bukan literal
/// yang tersebar.
abstract final class AppColors {
  // ── Latar "mist" klinis-botani (WCAG AA/AAA terverifikasi) ────────────
  static const mistTop = Color(0xFFF0F6F3);
  static const mistBottom = Color(0xFFF6F9F7);

  // ── Aksen merek ────────────────────────────────────────────────────────
  /// Hijau hutan klinis: tombol utama, fokus, dan status aktif (8.51:1).
  static const darkAccent = Color(0xFF1E5643);

  /// Kanopi gelap untuk permukaan aksi utama berkontras tinggi (12.35:1).
  static const forestDeep = Color(0xFF163B2F);

  /// Aqua-sage lembut untuk permukaan indikator & status aktif ringan.
  static const aquaSage = Color(0xFFD9EAE3);

  /// Mint sangat lembut untuk pill aktif & kotak ikon.
  static const mintTint = Color(0xFFE3F1EB);

  /// Permukaan sekunder halus untuk strip metrik & jadwal.
  static const surfaceTint = Color(0xFFEAF2EE);

  /// Hijau lidah buaya untuk ilustrasi botani.
  static const aloe = Color(0xFF3E8464);

  // ── Teks (WCAG 2.2 AA/AAA) ─────────────────────────────────────────────
  /// Teks utama (15.66:1 di mist, 16.77:1 di putih).
  static const textPrimary = Color(0xFF14201B);

  /// Teks sekunder (6.46:1 di putih, 6.03:1 di mist).
  static const textSecondary = Color(0xFF51625C);

  /// Teks sekunder di atas permukaan tint/kaca (≥ 5.6:1).
  static const textSecondaryOnGlass = Color(0xFF475852);

  // ── Permukaan & garis tepi ─────────────────────────────────────────────
  static const white = Color(0xFFFFFFFF);
  static const glassFill = Color(0xFAFFFFFF); // putih 98 % — tajam & terbaca
  static const glassFillStrong = Color(0xFFFFFFFF);
  static const glassBorder = Color(0xFFD2DFD9); // garis tepi klinis 1 px
  static const glassShadow = Color(0x0D14201B); // bayangan tipis 5 %

  /// Scrim halus di bawah overlay/panel di atas foto.
  static const panelScrim = Color(0xE6F4F8F6);

  // ── Ilustrasi botani & latar editorial ────────────────────────────────
  /// Sisi gelap daun (kanal tengah) dan bayangan dasar rumpun.
  static const aloeShade = Color(0xFF3E6F4F);

  /// Tepi, gerigi, dan kilau daun.
  static const aloeHighlight = Color(0xFFE6F1EB);

  /// Kabut sage di sisi kiri. Putih di atasnya (opasitas ≥ 80 %) ≥ 3:1,
  /// cukup untuk teks besar "Natural" menurut WCAG AA.
  static const sageVeil = Color(0xFF5F877B);
  static const sageMist = Color(0xFFA9C9B3);
  static const cream = Color(0xFFF2EBE0);

  static const mistGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [mistTop, mistBottom],
  );
}
