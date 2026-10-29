import 'dart:ui' show ImageFilter, PathOperation;

import 'package:flutter/widgets.dart';

import'../../../core/theme/app_colors.dart';
import'../../../core/theme/app_spacing.dart';

/// Permukaan kaca buram (frosted glass).
///
/// - `BackdropFilter` blur di belakang permukaan (dimatikan bila
///   [blurSigma] = 0, misalnya untuk elemen yang sudah berada di atas kaca).
/// - Isi putih transparan + garis tepi putih tipis.
/// - Bayangan hanya dilukis di LUAR bentuk, sehingga tidak menggelapkan latar
///   yang terlihat menembus kaca.
/// - `RepaintBoundary` agar animasi di sekitarnya tidak memaksa area blur
///   dilukis ulang.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppRadii.panel)),
    this.padding = EdgeInsets.zero,
    this.blurSigma = 24,
    this.fill = AppColors.glassFill,
    this.borderColor = AppColors.glassBorder,
    this.shadows = panelShadow,
  });

  /// Bayangan lembut ke atas untuk panel yang naik dari dasar layar
  /// (0 -10 40 rgba(0,0,0,0.06)).
  static const panelShadow = <BoxShadow>[
    BoxShadow(
      color: AppColors.glassShadow,
      blurRadius: 40,
      offset: Offset(0, -10),
    ),
  ];

  /// Blur latar untuk elemen kecil yang melayang langsung di atas foto
  /// (mis. pill logo); panel besar memakai 24.
  static const floatingBlur = 16.0;

  /// Bayangan halus ke bawah untuk pill/kartu kecil yang melayang.
  static const floatingShadow = <BoxShadow>[
    BoxShadow(
      color: AppColors.glassShadow,
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final double blurSigma;
  final Color fill;
  final Color borderColor;
  final List<BoxShadow> shadows;

  @override
  Widget build(BuildContext context) {
    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor),
      ),
      child: Padding(padding: padding, child: child),
    );
    if (blurSigma > 0) {
      surface = ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: surface,
        ),
      );
    }
    surface = RepaintBoundary(child: surface);
    if (shadows.isEmpty) return surface;
    return CustomPaint(
      painter: _OuterShadowPainter(borderRadius, shadows),
      child: surface,
    );
  }
}

/// Melukis [shadows] di luar [borderRadius] saja.
class _OuterShadowPainter extends CustomPainter {
  const _OuterShadowPainter(this.borderRadius, this.shadows);

  final BorderRadius borderRadius;
  final List<BoxShadow> shadows;

  @override
  void paint(Canvas canvas, Size size) {
    final shape = borderRadius.toRRect(Offset.zero & size);
    var reach = 0.0;
    for (final shadow in shadows) {
      final extent =
          shadow.blurRadius * 2 + shadow.spreadRadius + shadow.offset.distance;
      if (extent > reach) reach = extent;
    }
    final outside = Path.combine(
      PathOperation.difference,
      Path()..addRect((Offset.zero & size).inflate(reach)),
      Path()..addRRect(shape),
    );
    canvas
      ..save()
      ..clipPath(outside);
    for (final shadow in shadows) {
      canvas.drawRRect(
        shape.shift(shadow.offset).inflate(shadow.spreadRadius),
        Paint()
          ..color = shadow.color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurSigma),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OuterShadowPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.shadows != shadows;
}
