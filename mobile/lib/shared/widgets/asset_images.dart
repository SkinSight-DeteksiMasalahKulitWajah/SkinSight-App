import 'dart:math' as math;

import 'package:flutter/material.dart';

import'../../core/app_assets.dart';
import'../../core/theme/app_colors.dart';
import'../../core/theme/app_motion.dart';

/// `errorBuilder` bersama untuk setiap `Image.asset`: bila gambar gagal
/// dimuat, tampil placeholder lembut, bukan area kosong atau error merah.
Widget assetErrorBuilder(
  BuildContext context,
  Object error,
  StackTrace? stackTrace,
) =>
    const AssetErrorPlaceholder();

/// Placeholder netral bernuansa sage dengan ikon daun.
class AssetErrorPlaceholder extends StatelessWidget {
  const AssetErrorPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Gambar tidak tersedia',
      image: true,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [AppColors.mistBottom, AppColors.aquaSage],
            radius: 1.1,
          ),
        ),
        child: LayoutBuilder(builder: (context, constraints) {
          final side = constraints.biggest.shortestSide;
          return Center(
            child: Icon(
              Icons.eco_outlined,
              size: side.isFinite ? math.max(12, side * .36) : 24,
              color: AppColors.aloe.withValues(alpha: .7),
            ),
          );
        }),
      ),
    );
  }
}

/// Gambar aset yang boleh belum ada di repo.
///
/// Keberadaan aset dicek lewat AssetManifest lebih dulu; bila tidak terdaftar,
/// [fallback] langsung ditampilkan tanpa request jaringan (tidak ada 404 di
/// Flutter Web). Bila ada, foto muncul dengan crossfade, dan `errorBuilder`
/// tetap jatuh ke [fallback] jika file rusak.
class OptionalAssetImage extends StatefulWidget {
  const OptionalAssetImage({
    super.key,
    required this.asset,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.semanticLabel,
    this.cacheHeight,
  });

  final String asset;
  final Widget fallback;
  final BoxFit fit;
  final Alignment alignment;
  final String? semanticLabel;

  /// Tinggi dekode (px fisik); lihat [portraitCacheHeight].
  final int? cacheHeight;

  /// Provider yang sama persis dengan yang dipakai widget ini, untuk
  /// `precacheImage` (kunci cache harus identik agar tidak didekode dua kali).
  static ImageProvider providerFor(String asset, {int? cacheHeight}) =>
      ResizeImage.resizeIfNeeded(null, cacheHeight, AssetImage(asset));

  @override
  State<OptionalAssetImage> createState() => _OptionalAssetImageState();
}

class _OptionalAssetImageState extends State<OptionalAssetImage> {
  late Future<bool> _available = AppAssets.exists(widget.asset);

  @override
  void didUpdateWidget(covariant OptionalAssetImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) {
      _available = AppAssets.exists(widget.asset);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _available,
      builder: (context, snapshot) {
        final child = snapshot.data == true
            ? Image(
                key: const ValueKey('photo'),
                image: OptionalAssetImage.providerFor(
                  widget.asset,
                  cacheHeight: widget.cacheHeight,
                ),
                fit: widget.fit,
                alignment: widget.alignment,
                semanticLabel: widget.semanticLabel,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) => widget.fallback,
              )
            : KeyedSubtree(
                key: const ValueKey('fallback'),
                child: widget.fallback,
              );
        return AnimatedSwitcher(
          duration: AppMotion.slow,
          switchInCurve: AppMotion.curve,
          layoutBuilder: (current, previous) => Stack(
            fit: StackFit.expand,
            children: [...previous, if (current != null) current],
          ),
          child: child,
        );
      },
    );
  }
}

/// Tinggi dekode untuk foto potret layar penuh (asumsi sumber 9:16).
///
/// Dengan `BoxFit.cover`, foto 9:16 di layar yang lebih lebar diskalakan
/// menurut lebar, sehingga tinggi yang dibutuhkan = lebar × 16/9.
/// `ResizeImage` tidak memperbesar melebihi ukuran asli.
int portraitCacheHeight(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  final dpr = MediaQuery.devicePixelRatioOf(context);
  final logical = math.max(size.height, size.width * 16 / 9);
  return (logical * dpr).clamp(480, 2560).round();
}

/// Lebar dekode (`cacheWidth`) untuk thumbnail foto pengguna selebar
/// [logicalWidth] dengan `BoxFit.cover`.
///
/// Foto kamera/galeri bisa ±1600 × 2100 px. Tanpa batas ini setiap thumbnail
/// kecil didekode penuh (±13 MB RAM per foto), sehingga daftar foto terasa
/// berat di HP. Faktor 1,5 menjaga foto lanskap (hingga 3:2) tetap tajam saat
/// dipotong; `ResizeImage` tidak pernah memperbesar melebihi ukuran asli.
int thumbnailCacheWidth(BuildContext context, double logicalWidth) =>
    (logicalWidth * MediaQuery.devicePixelRatioOf(context) * 1.5).round();
