/// Sistem jarak berbasis 8 px. Pakai konstanta ini, bukan angka langsung.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;

  /// Padding horizontal layar.
  static const screen = xl;

  /// Padding di dalam panel kaca.
  static const panel = xl;

  /// Target sentuh minimum (WCAG / Material).
  static const touchTarget = 44.0;

  /// Lebar konten maksimum untuk layar bergaya ponsel di web.
  static const maxContentWidth = 430.0;
}

/// Radius sudut yang dipakai bersama.
abstract final class AppRadii {
  static const pill = 999.0;

  /// Sudut atas panel kaca yang naik dari dasar layar.
  static const panel = 34.0;
}
