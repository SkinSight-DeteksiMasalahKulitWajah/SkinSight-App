import 'package:flutter/widgets.dart';

import '../../theme/app_motion.dart';

/// Urutan masuk layar pembuka pada satu `AnimationController`.
///
/// Setiap langkah berjarak [AppMotion.stagger] (120 ms) dan berlangsung
/// [AppMotion.slow] (600 ms) dengan `easeOutCubic`:
/// foto → kolom kaca → "Natural" → tag → headline → CTA → tautan masuk.
abstract final class OnboardingTimeline {
  static const total = Duration(milliseconds: 1320);

  static const photo = OnboardingStep(0);
  static const strip = OnboardingStep(1);
  static const word = OnboardingStep(2);
  static const tag = OnboardingStep(3);
  static const headline = OnboardingStep(4);
  static const cta = OnboardingStep(5);
  static const link = OnboardingStep(6);
}

/// Satu langkah dalam [OnboardingTimeline].
class OnboardingStep {
  const OnboardingStep(this.order);

  final int order;

  /// Progres langkah ini (0–1, sudah melalui kurva) untuk nilai controller [t].
  double valueAt(double t) {
    final total = OnboardingTimeline.total.inMilliseconds;
    final start = order * AppMotion.stagger.inMilliseconds / total;
    final end = (start + AppMotion.slow.inMilliseconds / total).clamp(0.0, 1.0);
    return Interval(start, end, curve: AppMotion.curve).transform(t);
  }
}

/// Fade + geser kecil untuk satu elemen dalam urutan masuk.
class StaggeredEntry extends StatelessWidget {
  const StaggeredEntry({
    super.key,
    required this.controller,
    required this.step,
    required this.child,
    this.offset = const Offset(0, 12),
  });

  final Animation<double> controller;
  final OnboardingStep step;
  final Widget child;

  /// Posisi awal relatif terhadap posisi akhir (px logis).
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      child: child,
      builder: (context, child) {
        final t = step.valueAt(controller.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: offset * (1 - t), child: child),
        );
      },
    );
  }
}
