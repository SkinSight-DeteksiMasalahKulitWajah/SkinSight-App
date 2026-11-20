import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import'./app_colors.dart';

/// Token presentasi bersama SkinSight. Nilai medis dan perilaku repository
/// berada di luar file ini.
///
/// Gaya "soft glassmorphism": latar sage pucat, kartu kaca buram putih,
/// aksen hampir-hitam untuk aksi utama, dan aqua-sage untuk lencana/cincin.
/// Nama token lama dipertahankan agar seluruh halaman ikut berganti gaya.
/// Warna inti merujuk ke [AppColors] agar hanya ada satu sumber nilai.
abstract final class SkinTokens {
  // ── Keluarga huruf (hanya sans-serif modern — tanpa serif) ────────────
  static const sans = 'PlusJakartaSans';
  static const serif = sans;

  // ── Aksen ──────────────────────────────────────────────────────────────
  /// Aksen utama gelap: tombol penting & status aktif.
  static const primary = AppColors.darkAccent;
  static const primaryDark = AppColors.textPrimary;

  /// Hijau aloe untuk ilustrasi & aksen alami.
  static const primaryBright = AppColors.aloe;
  static const primaryDeep = Color(0xFF111413);
  static const aloe = primaryBright;

  /// Aqua-sage lembut untuk lencana ikon dan status aktif.
  static const aqua = AppColors.aquaSage;
  static const aquaDeep = Color(0xFF1E5643);

  // ── Netral ─────────────────────────────────────────────────────────────
  static const ink = AppColors.textPrimary;
  static const muted = AppColors.textSecondary;
  static const subtle = Color(0xFF7B8C85);
  static const background = AppColors.mistTop;
  static const backgroundLight = AppColors.mistBottom;
  static const surface = AppColors.white;
  static const surfaceAlt = AppColors.surfaceTint;
  static const border = Color(0xFFD2DFD9);
  static const borderStrong = Color(0xFFB8CAC2);

  // ── Permukaan kartu ────────────────────────────────────────────────────
  static const glass = AppColors.glassFill;
  static const glassStrong = AppColors.glassFillStrong;
  static const glassSoft = Color(0xCCFFFFFF);
  static const glassBorder = AppColors.glassBorder;
  static const glassBlur = 16.0;

  // ── Tint lembut ────────────────────────────────────────────────────────
  static const mint = AppColors.mintTint;
  static const mintStrong = aqua;
  static const cyan = Color(0xFFE2EEEC);
  static const hero = AppColors.forestDeep;
  static const peach = Color(0xFFC46D4E);
  static const peachSoft = Color(0xFFF9ECE6);

  // ── Semantik (terverifikasi WCAG AA ≥ 5.4:1) ───────────────────────────
  static const coral = Color(0xFFA83B46);
  static const coralSoft = Color(0xFFFBECEF);
  static const amber = Color(0xFF7A5210);
  static const amberSoft = Color(0xFFFBF3E1);
  static const blue = Color(0xFF2F6472);
  static const blueSoft = Color(0xFFE3EFF2);
  static const lavender = Color(0xFF5D5994);
  static const lavenderSoft = Color(0xFFECEBF6);
  static const success = Color(0xFF1E5643);
  static const successSoft = Color(0xFFE3F1EB);

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
  /// Gradien aksi hutan klinis untuk tombol & elemen aktif.
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF23644E), Color(0xFF163B2F)],
  );

  /// Panel gelap untuk kartu ringkasan berkontras tinggi.
  static const deepGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E5643), Color(0xFF163B2F), Color(0xFF102B22)],
    stops: [0, .6, 1],
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
  // Seluruh hierarki memakai satu keluarga sans geometris (Plus Jakarta Sans).
  static const display = TextStyle(
    fontFamily: sans,
    fontSize: 32,
    height: 1.12,
    fontWeight: FontWeight.w800,
    color: ink,
    letterSpacing: -.6,
  );
  static const title = TextStyle(
    fontFamily: sans,
    fontSize: 24,
    height: 1.18,
    fontWeight: FontWeight.w800,
    color: ink,
    letterSpacing: -.4,
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
        fontFamily: sans,
        fontSize: 72,
        height: 1.0,
        fontWeight: FontWeight.w700,
        color: ink,
        letterSpacing: 6,
      ),
      displayMedium: TextStyle(
        fontFamily: sans,
        fontSize: 36,
        height: 1.1,
        fontWeight: FontWeight.w800,
        color: ink,
        letterSpacing: -.6,
      ),
      displaySmall: TextStyle(
        fontFamily: sans,
        fontSize: 28,
        height: 1.15,
        fontWeight: FontWeight.w700,
        color: ink,
        letterSpacing: -.4,
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
          fontFamily: sans,
          fontSize: 20,
          height: 1.25,
          fontWeight: FontWeight.w800,
          letterSpacing: -.3,
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
