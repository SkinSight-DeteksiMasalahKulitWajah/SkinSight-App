import 'package:flutter/widgets.dart';

/// Durasi & kurva gerak bersama (200–600 ms, easeOutCubic).
abstract final class AppMotion {
  static const fast = Duration(milliseconds: 200);
  static const medium = Duration(milliseconds: 400);
  static const slow = Duration(milliseconds: 600);

  /// Jeda antar-elemen pada animasi masuk bertahap.
  static const stagger = Duration(milliseconds: 120);
  static const curve = Curves.easeOutCubic;

  /// Jumlah siklus animasi dekoratif berulang (ilustrasi melayang, denyut
  /// jaring pindai) sebelum berhenti di posisi diam. Animasi yang berputar
  /// terus memaksa seluruh layar — termasuk blur kaca — digambar ulang
  /// setiap frame, yang membuat HP panas & boros baterai walau layar diam.
  static const ambientCycles = 3;

  /// Pengguna meminta gerak dikurangi (MediaQuery.disableAnimations).
  static bool reduceMotion(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Animasi berulang (denyut, chevron) hanya berjalan di aplikasi sungguhan:
  /// tidak saat gerak dikurangi, dan tidak di widget test agar
  /// `pumpAndSettle` tetap selesai.
  static bool loops(BuildContext context) {
    if (reduceMotion(context)) return false;
    return WidgetsBinding.instance.runtimeType == WidgetsFlutterBinding;
  }
}
