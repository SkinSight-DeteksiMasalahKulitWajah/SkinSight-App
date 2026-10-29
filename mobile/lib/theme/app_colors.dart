import 'package:flutter/painting.dart';

/// Palet SkinSight: satu-satunya tempat nilai warna heksadesimal.
///
/// `ThemeData`/`ColorScheme` (lihat `skin_theme.dart`) dibangun dari nilai di
/// sini, dan widget membaca warna lewat tema atau kelas ini, bukan literal
/// yang tersebar.
abstract final class AppColors {
  // ── Latar "mist" ───────────────────────────────────────────────────────
  static const mistTop = Color(0xFFE8EEEA);
  static const mistBottom = Color(0xFFF3F6F4);

  // ── Aksen ──────────────────────────────────────────────────────────────
  /// Hampir hitam: tombol utama dan status aktif.
  static const darkAccent = Color(0xFF1A1A1A);

  /// Aqua-sage lembut: lencana ikon dan cincin progres.
  static const aquaSage = Color(0xFFBFD8D2);

  /// Hijau lidah buaya untuk ilustrasi botani.
  static const aloe = Color(0xFF5E9B6B);

  // ── Teks ───────────────────────────────────────────────────────────────
  static const textPrimary = Color(0xFF1F2A27);
  static const textSecondary = Color(0xFF6B7B76);

  /// Teks sekunder berukuran kecil (< 18 px) di atas kaca putih.
  /// [textSecondary] hanya ±4,3:1 di sana (gagal WCAG AA 4,5:1), nilai ini
  /// ±5,4:1. [textSecondary] tetap dipakai untuk teks besar & ikon.
  static const textSecondaryOnGlass = Color(0xFF5B6B66);

  // ── Kaca ───────────────────────────────────────────────────────────────
  static const white = Color(0xFFFFFFFF);
  static const glassFill = Color(0x9EFFFFFF); // putih 62 %
  static const glassFillStrong = Color(0xBFFFFFFF); // putih 75 %
  static const glassBorder = Color(0x99FFFFFF); // putih 60 %
  static const glassShadow = Color(0x0F000000); // hitam 6 %

  /// Mist 75 % di bawah panel kaca: apa pun yang ada di belakang panel
  /// (foto/daun) diredam sehingga teks sekunder tetap ≥ 4,5:1.
  static const panelScrim = Color(0xBFF3F6F4);

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
