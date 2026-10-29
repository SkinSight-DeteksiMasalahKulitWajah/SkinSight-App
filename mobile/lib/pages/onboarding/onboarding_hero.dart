import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_assets.dart';
import '../../theme/app_motion.dart';
import '../../widgets/asset_images.dart';
import 'onboarding_backdrop.dart';
import 'onboarding_panel.dart';

/// Layar pembuka SkinSight (gaya editorial "Natural").
///
/// Lapisan: [OnboardingBackdrop] (foto, kolom kaca buram, kata "Natural",
/// aloe 3D) di belakang, lalu [OnboardingPanel] (tag, headline, CTA geser)
/// yang menempel di bawah. Konten depan bisa digulir bila layar sangat pendek
/// atau ukuran teks sistem besar, jadi tidak pernah overflow.
class OnboardingHero extends StatefulWidget {
  const OnboardingHero({
    super.key,
    required this.onStart,
    required this.onLogin,
    this.interactiveKeys = true,
  });

  final VoidCallback onStart;
  final VoidCallback onLogin;

  /// False untuk salinan di dalam mockup etalase agar key tidak ganda.
  final bool interactiveKeys;

  @override
  State<OnboardingHero> createState() => _OnboardingHeroState();
}

class _OnboardingHeroState extends State<OnboardingHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1320),
  )..addStatusListener((_) => _maybeFreezeBackdrop());

  /// Latar (foto ×2, kolom blur, kata "Natural") diam setelah animasi masuk.
  /// Saat itu ia dibekukan menjadi satu gambar, sehingga geser CTA & kedip
  /// chevron hanya menggambar ulang satu tekstur, bukan foto + blur.
  final _backdropSnapshot = SnapshotController();
  bool _imagesReady = false;
  bool _precacheRequested = false;

  /// Snapshot baru diambil setelah SEMUA gambar latar selesai didekode;
  /// kalau lebih awal, foto yang datang belakangan tidak akan pernah tampil.
  void _maybeFreezeBackdrop() {
    if (_imagesReady && _entry.isCompleted) {
      _backdropSnapshot.allowSnapshotting = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduceMotion(context)) {
      _entry.value = 1;
    } else if (_entry.isDismissed) {
      _entry.forward();
    }
    if (!_precacheRequested) {
      _precacheRequested = true;
      // Dekode foto & aloe lebih awal agar tidak "berkedip" saat masuk.
      // Provider harus identik dengan yang dipakai latar (kunci cache sama).
      final cacheHeight = portraitCacheHeight(context);
      Future.wait([
        for (final image in [
          OptionalAssetImage.providerFor(
            AppAssets.heroPortrait,
            cacheHeight: cacheHeight,
          ),
          OptionalAssetImage.providerFor(
            AppAssets.heroSubject,
            cacheHeight: cacheHeight,
          ),
          const AssetImage(AppAssets.aloe3d),
        ])
          precacheImage(image, context, onError: (_, __) {}),
      ]).then((_) {
        if (!mounted) return;
        _imagesReady = true;
        _maybeFreezeBackdrop();
      });
    } else {
      // Ukuran layar, rasio piksel, atau skala teks berubah: ambil ulang.
      _backdropSnapshot.clear();
    }
  }

  @override
  void dispose() {
    _entry.dispose();
    _backdropSnapshot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Batasi skala teks di layar pembuka agar komposisi tetap utuh; halaman
    // lain tetap mengikuti pengaturan pengguna sepenuhnya.
    final media = MediaQuery.of(context);
    final scaler = media.textScaler.clamp(maxScaleFactor: 1.3);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: MediaQuery(
        data: media.copyWith(textScaler: scaler),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: SnapshotWidget(
                controller: _backdropSnapshot,
                autoresize: true,
                child: OnboardingBackdrop(controller: _entry),
              ),
            ),
            CustomScrollView(
              key: widget.interactiveKeys ? const Key('start-scroll') : null,
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: math.max(
                              360,
                              math.min(media.size.width, 500),
                            ),
                          ),
                          child: OnboardingPanel(
                            controller: _entry,
                            interactiveKeys: widget.interactiveKeys,
                            onStart: widget.onStart,
                            onLogin: widget.onLogin,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
