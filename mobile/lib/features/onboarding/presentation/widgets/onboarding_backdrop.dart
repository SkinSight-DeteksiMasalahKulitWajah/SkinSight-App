import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import'../../../../core/app_assets.dart';
import'../../../../core/theme/app_colors.dart';
import'../../../../shared/widgets/asset_images.dart';
import'./onboarding_motion.dart';
import'./onboarding_strings.dart';
import'./vertical_display_word.dart';

/// Latar penuh layar pembuka, mengikuti referensi desain:
///
/// 1. Foto potret full-bleed (subjek di kanan) + rumpun lidah buaya 3D.
/// 2. Kolom kaca buram di sisi kiri (±43 % lebar) dengan garis tepi tipis —
///    dibuat dari salinan buram adegan yang sama, sehingga daun & tangan di
///    belakangnya ikut kabur tanpa `BackdropFilter` (aman untuk animasi).
/// 3. Kata vertikal "Natural" berhuruf serif tipis di dalam kolom kaca.
/// 4. Pudar lembut ke warna mist di bagian bawah, tempat teks & CTA berada.
class OnboardingBackdrop extends StatelessWidget {
  const OnboardingBackdrop({super.key, required this.controller});

  final Animation<double> controller;

  /// Lebar kolom kaca untuk lebar layar [width].
  static double stripWidthFor(double width) =>
      (width * .43).clamp(120.0, 320.0);

  /// Batas bawah kolom kaca (proporsi tinggi layar) sebelum memudar.
  /// Layar pendek memberi ruang lebih besar untuk teks & CTA di bawah.
  static double stripEndFor(double height) => height < 700 ? .6 : .74;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;
      final stripWidth = stripWidthFor(size.width);
      final topInset = MediaQuery.paddingOf(context).top;
      final stripEnd = stripEndFor(size.height);
      // Blur ringan (±20 % dari versi awal) agar latar tetap terbaca.
      const blurSigma = 3.0;

      return RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: AppColors.mistBottom),
            // ── 1. Adegan tajam ──────────────────────────────────────────
            _Animated(
              controller: controller,
              step: OnboardingTimeline.photo,
              builder: (t, child) => Opacity(
                opacity: t,
                child: Transform.scale(scale: 1.05 - .05 * t, child: child),
              ),
              child: _Scene(size: size, semantic: true),
            ),
            // ── 2. Kolom kaca buram ──────────────────────────────────────
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: stripWidth,
              child: _Animated(
                controller: controller,
                step: OnboardingTimeline.strip,
                builder: (t, child) => Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: 1,
                  child: ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: t.clamp(0.0001, 1.0),
                      child: child,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: stripWidth,
                  child: _FrostedStrip(
                    size: size,
                    stripEnd: stripEnd,
                    blurSigma: blurSigma,
                    controller: controller,
                  ),
                ),
              ),
            ),
            // ── 3. Kata vertikal ─────────────────────────────────────────
            Positioned(
              // Kotak kata di tengah kolom kaca (kiri-kanan simetris) dan
              // berhenti di atas area pudar agar huruf "N" tidak terpotong.
              left: stripWidth * .09,
              width: stripWidth * .82,
              top: topInset + size.height * .035,
              bottom: size.height * (1 - stripEnd + .13),
              child: StaggeredEntry(
                controller: controller,
                step: OnboardingTimeline.word,
                offset: const Offset(0, 28),
                child: const VerticalDisplayWord(
                  OnboardingStrings.verticalWord,
                ),
              ),
            ),
            // ── 4. Pudar ke mist di bawah ────────────────────────────────
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.mistBottom.withValues(alpha: 0),
                      AppColors.mistBottom.withValues(alpha: .55),
                      AppColors.mistBottom.withValues(alpha: .94),
                      AppColors.mistBottom,
                    ],
                    stops: [
                      stripEnd - .22,
                      stripEnd - .06,
                      stripEnd + .06,
                      1,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// Foto + daun lidah buaya + nuansa sage. Dipakai dua kali: tajam (utama)
/// dan buram (di dalam kolom kaca), jadi posisinya harus identik.
class _Scene extends StatelessWidget {
  const _Scene({required this.size, this.semantic = false});

  final Size size;
  final bool semantic;

  @override
  Widget build(BuildContext context) {
    final cacheHeight = portraitCacheHeight(context);
    final w = size.width;
    final h = size.height;
    // Lebar rumpun aloe relatif layar; rasio aset ±1,58 : 1.
    final aloeWidth = (w * .95).clamp(250.0, 600.0);
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image(
            image: OptionalAssetImage.providerFor(
              AppAssets.heroPortrait,
              cacheHeight: cacheHeight,
            ),
            fit: BoxFit.cover,
            // Subjek ada di kanan foto; sedikit ke kanan & ke atas agar wajah
            // tetap di sepertiga atas pada layar lebar maupun ramping.
            alignment: const Alignment(.25, -.35),
            semanticLabel: semantic ? OnboardingStrings.portraitLabel : null,
            excludeFromSemantics: !semantic,
            gaplessPlayback: true,
            errorBuilder: assetErrorBuilder,
          ),
          // Aloe 3D: di atas latar foto, di bawah potongan subjek.
          Positioned(
            // Cukup tinggi agar daun yang menyeberang ke kanan tertutup
            // tangan & wajah (bagian subjek yang masih utuh, bukan area pudar).
            left: -aloeWidth * .36,
            top: h * .30,
            width: aloeWidth,
            child: Transform.rotate(
              angle: .31,
              // Tanpa cacheWidth: sumbernya hanya 799 px (di HP selalu
              // didekode penuh), dan provider jadi sama dengan precache di
              // OnboardingHero sehingga tidak didekode dua kali.
              child: Image.asset(
                AppAssets.aloe3d,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          // Potongan subjek (latar transparan) di atas aloe, sehingga daun
          // tampak berada DI BELAKANG wajah & tangan.
          Image(
            image: OptionalAssetImage.providerFor(
              AppAssets.heroSubject,
              cacheHeight: cacheHeight,
            ),
            fit: BoxFit.cover,
            alignment: const Alignment(.25, -.35),
            excludeFromSemantics: true,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          // Nuansa abu-sage seperti studio, wajah tetap netral.
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(.25, -.42),
                  radius: 1.05,
                  colors: [
                    AppColors.mistTop.withValues(alpha: 0),
                    AppColors.mistTop.withValues(alpha: .18),
                    AppColors.mistTop.withValues(alpha: .62),
                  ],
                  stops: const [.38, .7, 1],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kolom kaca: salinan adegan yang dibuat buram, lapisan putih tipis, dan
/// garis tepi kanan. Memudar ke bawah agar menyatu dengan area teks.
class _FrostedStrip extends StatelessWidget {
  const _FrostedStrip({
    required this.size,
    required this.stripEnd,
    required this.blurSigma,
    required this.controller,
  });

  final Size size;
  final double stripEnd;
  final double blurSigma;
  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    final fadeFrom = stripEnd - .08;
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.white,
          AppColors.white,
          AppColors.white.withValues(alpha: 0),
        ],
        stops: [0, fadeFrom, stripEnd + .04],
      ).createShader(bounds),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: size.width,
              maxWidth: size.width,
              minHeight: size.height,
              maxHeight: size.height,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: blurSigma,
                  sigmaY: blurSigma,
                  tileMode: TileMode.mirror,
                ),
                child: _Animated(
                  controller: controller,
                  step: OnboardingTimeline.photo,
                  builder: (t, child) => Transform.scale(
                    scale: 1.05 - .05 * t,
                    child: child,
                  ),
                  child: _Scene(size: size),
                ),
              ),
            ),
          ),
          // Kilau kaca: sedikit lebih terang di kiri.
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.white.withValues(alpha: .30),
                    AppColors.white.withValues(alpha: .14),
                  ],
                ),
                border: Border(
                  right: BorderSide(
                    color: AppColors.white.withValues(alpha: .85),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// AnimatedBuilder kecil yang memetakan controller ke progres satu langkah.
class _Animated extends StatelessWidget {
  const _Animated({
    required this.controller,
    required this.step,
    required this.builder,
    required this.child,
  });

  final Animation<double> controller;
  final OnboardingStep step;
  final Widget Function(double t, Widget child) builder;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      child: child,
      builder: (context, child) =>
          builder(step.valueAt(controller.value), child!),
    );
  }
}
