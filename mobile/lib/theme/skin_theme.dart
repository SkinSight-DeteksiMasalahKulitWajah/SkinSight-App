import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Token presentasi bersama SkinSight. Nilai medis dan perilaku repository
/// berada di luar file ini.
///
/// Gaya "soft glassmorphism": latar sage pucat, kartu kaca buram putih,
/// aksen hampir-hitam untuk aksi utama, dan aqua-sage untuk lencana/cincin.
/// Nama token lama dipertahankan agar seluruh halaman ikut berganti gaya.
/// Warna inti merujuk ke [AppColors] agar hanya ada satu sumber nilai.
abstract final class SkinTokens {
  // ── Keluarga huruf ─────────────────────────────────────────────────────
  static const sans = 'PlusJakartaSans';
  static const serif = 'CormorantGaramond';

  // ── Aksen ──────────────────────────────────────────────────────────────
  /// Aksen utama gelap: tombol penting & status aktif.
  static const primary = AppColors.darkAccent;
  static const primaryDark = AppColors.textPrimary;

  /// Hijau aloe untuk ilustrasi & aksen alami.
  static const primaryBright = AppColors.aloe;
  static const primaryDeep = Color(0xFF111413);
  static const aloe = primaryBright;

  /// Aqua-sage lembut untuk lencana ikon dan cincin progres.
  static const aqua = AppColors.aquaSage;
  static const aquaDeep = Color(0xFF7FB0A4);

  // ── Netral ─────────────────────────────────────────────────────────────
  static const ink = AppColors.textPrimary;
  static const muted = AppColors.textSecondary;
  static const subtle = Color(0xFF9AA8A3);
  static const background = AppColors.mistTop;
  static const backgroundLight = AppColors.mistBottom;
  static const surface = AppColors.white;
  static const surfaceAlt = Color(0xFFF1F5F3);
  static const border = Color(0xFFDCE5E0);
  static const borderStrong = Color(0xFFC7D4CE);

  // ── Kaca ───────────────────────────────────────────────────────────────
  static const glass = Color(0x8CFFFFFF); // putih 55%
  static const glassStrong = AppColors.glassFillStrong; // putih 75%
  static const glassSoft = Color(0x59FFFFFF); // putih 35%
  static const glassBorder = AppColors.glassBorder; // putih 60%
  static const glassBlur = 20.0;

  // ── Tint lembut ────────────────────────────────────────────────────────
  static const mint = Color(0xFFDCEAE5);
  static const mintStrong = aqua;
  static const cyan = Color(0xFFE2EEEC);
  static const hero = aqua;
  static const peach = Color(0xFFD9967A);
  static const peachSoft = Color(0xFFF6EAE3);

  // ── Semantik (diredam agar selaras dengan palet sage) ──────────────────
  static const coral = Color(0xFFB4515B);
  static const coralSoft = Color(0xFFF5E5E6);
  static const amber = Color(0xFF94701F);
  static const amberSoft = Color(0xFFF4EDDC);
  static const blue = Color(0xFF4C7C88);
  static const blueSoft = Color(0xFFE2EDEF);
  static const lavender = Color(0xFF6C69A3);
  static const lavenderSoft = Color(0xFFEBEAF4);
  static const success = Color(0xFF3E7D57);
  static const successSoft = Color(0xFFE1EEE5);

  // ── Ruang & bentuk (basis 8) ───────────────────────────────────────────
  static const space = 16.0;
  static const pageInset = 24.0;
  static const radius = 24.0;
  static const controlRadius = 999.0;
  static const radiusSm = 16.0;
  static const radiusLg = 26.0;
  static const radiusXl = 32.0;
  static const radiusPill = 999.0;
  static const maxWidth = 520.0;

  // ── Elevasi: bayangan berlapis yang halus ──────────────────────────────
  static const shadows = <BoxShadow>[
    BoxShadow(color: Color(0x0F1F2A27), blurRadius: 30, offset: Offset(0, 12)),
    BoxShadow(color: Color(0x081F2A27), blurRadius: 6, offset: Offset(0, 2)),
  ];
  static const shadowsLifted = <BoxShadow>[
    BoxShadow(color: Color(0x1F1F2A27), blurRadius: 60, offset: Offset(0, 28)),
    BoxShadow(color: Color(0x0F1F2A27), blurRadius: 16, offset: Offset(0, 6)),
  ];

  static List<BoxShadow> glow(Color color, {double opacity = .30}) => [
        BoxShadow(
          color: color.withValues(alpha: opacity),
          blurRadius: 26,
          offset: const Offset(0, 12),
        ),
      ];

  // ── Gradien ────────────────────────────────────────────────────────────
  /// Gradien "aksi" gelap untuk tombol & elemen aktif.
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF34403C), Color(0xFF1A1A1A)],
  );

  /// Panel gelap untuk kartu ringkasan berkontras tinggi.
  static const deepGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B4944), Color(0xFF1F2A27), Color(0xFF141816)],
    stops: [0, .55, 1],
  );
  static const softGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE1EDE9), Color(0xFFF4F7F5)],
  );
  static const warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF4E9E1), Color(0xFFF8F4EF)],
  );
  static const sageGradient = AppColors.mistGradient;

  // ── Gerak ──────────────────────────────────────────────────────────────
  static const fast = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 420);

  // ── Tipografi ──────────────────────────────────────────────────────────
  // Display & title: serif kontras tinggi berbobot ringan.
  // Section, card & body: sans geometris modern (Plus Jakarta Sans).
  static const display = TextStyle(
    fontFamily: serif,
    fontSize: 38,
    height: 1.08,
    fontWeight: FontWeight.w400,
    color: ink,
    letterSpacing: -.4,
  );
  static const title = TextStyle(
    fontFamily: serif,
    fontSize: 32,
    height: 1.12,
    fontWeight: FontWeight.w500,
    color: ink,
    letterSpacing: -.2,
  );
  static const section = TextStyle(
    fontSize: 19,
    height: 1.25,
    fontWeight: FontWeight.w700,
    color: ink,
    letterSpacing: -.2,
  );
  static const cardTitle = TextStyle(
    fontSize: 16.5,
    height: 1.3,
    fontWeight: FontWeight.w700,
    color: ink,
  );
  static const body = TextStyle(fontSize: 16, height: 1.5, color: ink);
  static const caption = TextStyle(fontSize: 13, height: 1.5, color: muted);
  static const label = TextStyle(
    fontSize: 14,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: ink,
  );
  static const eyebrow = TextStyle(
    fontSize: 11,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: muted,
    letterSpacing: 1.4,
  );

  /// Angka tebal (75%, 22, dsb.).
  static const number = TextStyle(
    fontSize: 22,
    height: 1.1,
    fontWeight: FontWeight.w800,
    color: ink,
    letterSpacing: -.3,
  );

  static ThemeData theme({String fontFamily = sans}) {
    final scheme = ColorScheme.fromSeed(seedColor: aquaDeep).copyWith(
      primary: primary,
      onPrimary: surface,
      primaryContainer: mint,
      onPrimaryContainer: ink,
      secondary: aquaDeep,
      onSecondary: surface,
      secondaryContainer: aqua,
      onSecondaryContainer: ink,
      tertiary: aloe,
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: muted,
      surfaceContainerHighest: surfaceAlt,
      outline: borderStrong,
      outlineVariant: border,
      error: coral,
      surfaceTint: Colors.transparent,
    );
    const capsule = StadiumBorder();
    // Skala inti 12/14/16/20/32. Role display memakai serif Cormorant
    // Garamond untuk aksen editorial (mis. kata vertikal "Natural").
    const textTheme = TextTheme(
      displayLarge: TextStyle(
        fontFamily: serif,
        fontSize: 140,
        height: 1.0,
        fontWeight: FontWeight.w300,
        color: ink,
        letterSpacing: 14, // 0,1 em
      ),
      displayMedium: TextStyle(
        fontFamily: serif,
        fontSize: 44,
        height: 1.05,
        fontWeight: FontWeight.w300,
        color: ink,
        letterSpacing: -.4,
      ),
      // Aksen serif miring yang dipadukan dengan headlineLarge; sedikit lebih
      // besar untuk mengimbangi x-height Cormorant yang kecil.
      displaySmall: TextStyle(
        fontFamily: serif,
        fontSize: 38,
        height: 1.05,
        fontWeight: FontWeight.w300,
        fontStyle: FontStyle.italic,
        color: ink,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        height: 1.15,
        fontWeight: FontWeight.w600,
        color: ink,
        letterSpacing: -.3,
      ),
      headlineMedium: title,
      headlineSmall: TextStyle(
        fontSize: 22,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: ink,
        letterSpacing: -.3,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: ink,
        letterSpacing: -.2,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        height: 1.3,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleSmall: TextStyle(
        fontSize: 15,
        height: 1.35,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      bodyLarge: body,
      bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: ink),
      bodySmall: TextStyle(fontSize: 12, height: 1.5, color: muted),
      labelLarge: TextStyle(
        fontSize: 16,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        height: 1.25,
        fontWeight: FontWeight.w600,
        color: muted,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        height: 1.25,
        fontWeight: FontWeight.w600,
        color: muted,
        letterSpacing: .2,
      ),
    );
    TextStyle font(TextStyle style) => style.copyWith(fontFamily: fontFamily);
    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm + 4),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: backgroundLight,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      iconTheme: const IconThemeData(color: ink),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SkinPageTransitionsBuilder(),
          TargetPlatform.fuchsia: SkinPageTransitionsBuilder(),
          TargetPlatform.linux: SkinPageTransitionsBuilder(),
          TargetPlatform.windows: SkinPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: font(const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: ink,
        )),
        iconTheme: const IconThemeData(color: ink),
      ),
      cardTheme: CardThemeData(
        color: glassStrong,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: glassBorder),
        ),
      ),
      listTileTheme: ListTileThemeData(
        textColor: ink,
        iconColor: ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titleTextStyle: font(const TextStyle(
          fontSize: 15,
          height: 1.3,
          fontWeight: FontWeight.w700,
          color: ink,
        )),
        subtitleTextStyle: font(const TextStyle(
          fontSize: 13,
          height: 1.45,
          color: muted,
        )),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: backgroundLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
          side: const BorderSide(color: surface, width: 1.5),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: serif,
          fontSize: 26,
          height: 1.15,
          fontWeight: FontWeight.w500,
          color: ink,
        ),
        contentTextStyle: font(const TextStyle(
          fontSize: 14.5,
          height: 1.5,
          color: muted,
        )),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: backgroundLight,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: backgroundLight,
        showDragHandle: true,
        dragHandleColor: borderStrong,
        dragHandleSize: Size(40, 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: glassStrong,
        indicatorColor: surface,
        iconTheme: const WidgetStatePropertyAll(IconThemeData(color: ink)),
        labelTextStyle: WidgetStatePropertyAll(font(const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: ink,
        ))),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primary,
        contentTextStyle: font(const TextStyle(
          fontSize: 14,
          height: 1.4,
          color: surface,
        )),
        actionTextColor: aqua,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: glass,
        selectedColor: surface,
        disabledColor: surfaceAlt,
        checkmarkColor: ink,
        showCheckmark: false,
        side: WidgetStateBorderSide.resolveWith(
          (states) => BorderSide(
            color:
                states.contains(WidgetState.selected) ? surface : glassBorder,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: capsule,
        // Chip hanya me-resolve warna label per state, bukan seluruh style.
        labelStyle: font(TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.selected) ? ink : muted,
          ),
        )),
        secondaryLabelStyle: font(const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: ink,
        )),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        side: const BorderSide(color: borderStrong, width: 1.6),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : surface,
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? primary : borderStrong,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(surface),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? primary : borderStrong,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: aqua,
        thumbColor: primary,
        overlayColor: Color(0x141A1A1A),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: aqua,
        circularTrackColor: aqua,
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      dividerColor: border,
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: primary.withValues(alpha: .92),
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: font(const TextStyle(fontSize: 12, color: surface)),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: backgroundLight,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: primary,
        headerForegroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
        dayShape: const WidgetStatePropertyAll(CircleBorder()),
        todayBorder: const BorderSide(color: primary, width: 1.4),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: surface,
          disabledBackgroundColor: const Color(0xFFD5DEDA),
          disabledForegroundColor: const Color(0xFF8C9A95),
          minimumSize: const Size(44, 54),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: capsule,
          elevation: 0,
          textStyle: font(const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          )),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: surface,
          foregroundColor: ink,
          minimumSize: const Size(44, 54),
          shape: capsule,
          elevation: 0,
          textStyle: font(const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          )),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          backgroundColor: glassStrong,
          minimumSize: const Size(44, 54),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: capsule,
          side: const BorderSide(color: surface, width: 1.2),
          textStyle: font(const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
          )),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size(44, 44),
          shape: capsule,
          textStyle: font(const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            decorationColor: ink,
          )),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          foregroundColor: ink,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: surface,
        elevation: 0,
        shape: CircleBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glassStrong,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        labelStyle: font(const TextStyle(color: muted, fontSize: 15)),
        floatingLabelStyle: font(const TextStyle(
          color: ink,
          fontWeight: FontWeight.w700,
        )),
        hintStyle: font(const TextStyle(color: subtle, fontSize: 14.5)),
        prefixIconColor: muted,
        suffixIconColor: muted,
        border: inputBorder(surface),
        enabledBorder: inputBorder(surface),
        focusedBorder: inputBorder(primary, 1.4),
        errorBorder: inputBorder(coral),
        focusedErrorBorder: inputBorder(coral, 1.4),
      ),
    );
  }
}

/// Transisi halaman: memudar sambil bergeser halus dari kanan.
/// Menghormati pengaturan "kurangi animasi" pada perangkat.
class SkinPageTransitionsBuilder extends PageTransitionsBuilder {
  const SkinPageTransitionsBuilder();

  static final _offset = Tween<Offset>(
    begin: const Offset(.06, 0),
    end: Offset.zero,
  ).chain(CurveTween(curve: Curves.easeOutCubic));
  static final _opacity = CurveTween(curve: const Interval(0, .8));

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;
    return FadeTransition(
      opacity: animation.drive(_opacity),
      child: SlideTransition(
        position: animation.drive(_offset),
        child: child,
      ),
    );
  }
}
