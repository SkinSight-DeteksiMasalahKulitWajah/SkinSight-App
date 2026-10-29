import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import 'asset_images.dart';

/// Ilustrasi 3D (PNG transparan hasil render) dengan:
/// - dekode sesuai ukuran tampil (hemat memori di HP kelas bawah),
/// - animasi melayang halus opsional ([float]) selama
///   [AppMotion.ambientCycles] siklus, lalu diam; otomatis mati saat
///   "kurangi animasi" aktif atau di widget test,
/// - fallback lembut bila file gagal dimuat.
class Skin3D extends StatelessWidget {
  const Skin3D(
    this.asset, {
    super.key,
    this.size,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.float = false,
    this.floatDistance = 5,
    this.semanticLabel,
  });

  final String asset;

  /// Sisi kotak persegi; abaikan bila [width]/[height] diisi.
  final double? size;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;

  /// Animasi melayang naik-turun pelan.
  final bool float;
  final double floatDistance;

  /// Label aksesibilitas. Null = dekoratif (tidak dibacakan).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final w = width ?? size;
    final h = height ?? size;
    // Ukuran dekode dari ukuran tampil yang diketahui (tanpa LayoutBuilder
    // agar aman dipakai di dalam widget yang menghitung ukuran intrinsik).
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2;
    final longest = math.max(w ?? 0, h ?? 0);
    final cache = longest > 0 ? (longest * dpr).clamp(64, 1024).round() : null;
    Widget image = Image.asset(
      asset,
      fit: fit,
      alignment: alignment,
      cacheWidth: cache,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      excludeFromSemantics: semanticLabel == null,
      semanticLabel: semanticLabel,
      errorBuilder: assetErrorBuilder,
    );
    if (w != null || h != null) {
      image = SizedBox(width: w, height: h, child: image);
    }
    if (float) image = _Floating(distance: floatDistance, child: image);
    return image;
  }
}

class _Floating extends StatefulWidget {
  const _Floating({required this.child, required this.distance});

  final Widget child;
  final double distance;

  @override
  State<_Floating> createState() => _FloatingState();
}

class _FloatingState extends State<_Floating>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.loops(context)) {
      // Beberapa siklus lalu diam di posisi awal (sin 2π = 0).
      if (!_controller.isAnimating && _controller.isDismissed) {
        _controller.repeat(count: AppMotion.ambientCycles);
      }
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = math.sin(_controller.value * 2 * math.pi);
        return Transform.translate(
          offset: Offset(0, -widget.distance * t),
          child: child,
        );
      },
    );
  }
}
