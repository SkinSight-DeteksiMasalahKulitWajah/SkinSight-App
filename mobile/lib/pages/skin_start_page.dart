import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/skin_page_background.dart';
import '../widgets/skin_showcase.dart';
import 'onboarding/onboarding_hero.dart';

/// Halaman pembuka. Di ponsel tampil sebagai layar onboarding penuh;
/// di tablet/desktop menjadi etalase dengan tiga mockup ponsel.
class SkinStartPage extends StatelessWidget {
  const SkinStartPage({super.key});

  /// Lebar minimum untuk tata letak etalase (tablet ke atas).
  static const showcaseBreakpoint = 760.0;

  @override
  Widget build(BuildContext context) {
    void start() => Navigator.of(context).pushNamed('/auth');
    void login() => Navigator.of(context).pushNamed('/login');
    final wide = MediaQuery.sizeOf(context).width >= showcaseBreakpoint;

    return Scaffold(
      backgroundColor: AppColors.mistBottom,
      body: wide
          ? SkinPageBackground(
              child: SkinShowcase(onStart: start, onLogin: login),
            )
          : OnboardingHero(onStart: start, onLogin: login),
    );
  }
}
