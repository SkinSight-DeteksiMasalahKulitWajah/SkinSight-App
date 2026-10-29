import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/skin_education_content.dart';
import '../pages/onboarding/onboarding_hero.dart';
import '../theme/skin_theme.dart';
import 'skin_analysis_view.dart';
import 'skin_article_widgets.dart';
import 'skin_ui.dart';
import 'slide_to_start_button.dart';

// ───────────────────────── Mockup ─────────────────────────

/// Bingkai ponsel untuk etalase: sudut 40px, tepi putih dalam 2px,
/// bayangan dalam yang menyebar, status bar, dan dynamic island.
class SkinPhoneMockup extends StatelessWidget {
  const SkinPhoneMockup({super.key, required this.screen, this.width = 320});

  final Widget screen;
  final double width;

  static const _design = Size(390, 844);

  @override
  Widget build(BuildContext context) {
    final height = width * _design.height / _design.width;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: SkinTokens.backgroundLight,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E1F2A27),
            blurRadius: 90,
            spreadRadius: -6,
            offset: Offset(0, 44),
          ),
          BoxShadow(
            color: Color(0x141F2A27),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(38),
        child: FittedBox(
          child: SizedBox.fromSize(
            size: _design,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: _design,
                padding: const EdgeInsets.only(top: 52, bottom: 20),
                viewPadding: const EdgeInsets.only(top: 52, bottom: 20),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: SkinTokens.backgroundLight, child: screen),
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(child: _StatusBar()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Stack(
        children: [
          const Positioned(
            left: 34,
            top: 18,
            child: Text(
              '9:41',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: SkinTokens.ink,
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, .1),
            child: Container(
              width: 120,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const Positioned(
            right: 30,
            top: 19,
            child: Row(
              children: [
                Icon(Icons.signal_cellular_alt_rounded,
                    size: 16, color: SkinTokens.ink),
                SizedBox(width: 4),
                Icon(Icons.wifi_rounded, size: 16, color: SkinTokens.ink),
                SizedBox(width: 4),
                Icon(Icons.battery_full_rounded,
                    size: 18, color: SkinTokens.ink),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Pratinjau layar ─────────────────────────

/// Pratinjau dasbor untuk etalase (data contoh, bukan data pengguna).
class SkinDashboardPreview extends StatelessWidget {
  const SkinDashboardPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: SkinTokens.sageGradient),
      child: Stack(
        children: [
          ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 64, 22, 120),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(text: 'Halo '),
                        TextSpan(
                          text: 'Alea',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ]),
                      style: TextStyle(
                        fontSize: 30,
                        color: SkinTokens.ink,
                        letterSpacing: -.4,
                      ),
                    ),
                  ),
                  SkinGridMenuButton(onPressed: () {}),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Pendamping kulitmu mulai di sini!',
                style: TextStyle(fontSize: 13, color: SkinTokens.muted),
              ),
              const SizedBox(height: 18),
              SkinCard(
                radius: 30,
                padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Laporan Kulit',
                              style: SkinTokens.cardTitle),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const SkinRing(
                            value: .72,
                            size: 50,
                            stroke: 5,
                            child: SkinIconTile(
                              icon: Icons.spa_outlined,
                              size: 30,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Expanded(
                          child: SkinStatCapsule(
                            dark: true,
                            label: 'Skin Journey',
                            value: 'Minggu ke-3',
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: SkinStatCapsule(
                            label: 'Scan terakhir',
                            value: '2 hari lalu',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const SkinCard(
                radius: 999,
                padding: EdgeInsets.fromLTRB(10, 10, 18, 10),
                child: Row(
                  children: [
                    SkinIconTile(icon: Icons.schedule_rounded, size: 42),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('03 Sep',
                              style: TextStyle(
                                  fontSize: 12, color: SkinTokens.muted)),
                          Text(
                            'Check-in mingguan',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: SkinTokens.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text('Hari ini',
                        style:
                            TextStyle(fontSize: 12, color: SkinTokens.muted)),
                    Icon(Icons.play_arrow_rounded,
                        size: 18, color: SkinTokens.ink),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  children: [
                    for (final (i, label)
                        in ['Semua', 'Jerawat', 'Noda', 'Mata'].indexed) ...[
                      SkinFilterChip(
                        label: label,
                        selected: i == 0,
                        onTap: () {},
                      ),
                      const SizedBox(width: 6),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SkinSectionTitle(
                title: 'Untuk Kamu',
                trailing: SkinSeeAll(onTap: () {}),
              ),
              const SizedBox(height: 10),
              SkinForYouCard(article: skinArticles[1], onTap: () {}),
            ],
          ),
          const Positioned(
            left: 70,
            right: 70,
            bottom: 26,
            child: _PreviewNav(),
          ),
        ],
      ),
    );
  }
}

class _PreviewNav extends StatelessWidget {
  const _PreviewNav();

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, {bool on = false}) => Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: on ? Colors.white : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: SkinTokens.ink.withValues(alpha: .08)),
          ),
          child: Icon(icon, size: 21, color: SkinTokens.ink),
        );
    return SkinGlass(
      radius: 999,
      color: SkinTokens.glassStrong,
      borderColor: Colors.white,
      shadows: SkinTokens.shadowsLifted,
      padding: const EdgeInsets.all(6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          item(Icons.home_rounded, on: true),
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: SkinTokens.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.center_focus_weak_rounded,
                color: Colors.white),
          ),
          item(Icons.calendar_month_outlined),
        ],
      ),
    );
  }
}

/// Pratinjau layar analisis untuk etalase.
class SkinAnalysisPreview extends StatelessWidget {
  const SkinAnalysisPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: SkinTokens.backgroundLight),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(top: 44),
          child: SkinAnalysisView(
            badge: 'Jenis kulit: Kombinasi',
            photoHeight: 430,
            onBack: () {},
            recommendationLabel: 'Rekomendasi AI',
            metrics: const [
              (label: 'Jerawat', value: '30%', fraction: .3),
              (label: 'Kemerahan', value: '65%', fraction: .65),
              (label: 'Area mata', value: '15%', fraction: .15),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Etalase ─────────────────────────

/// Etalase untuk layar lebar: tablet dua kolom (+ satu di bawah, terpusat),
/// desktop tiga kolom dengan mockup tengah lebih besar.
class SkinShowcase extends StatelessWidget {
  const SkinShowcase({
    super.key,
    required this.onStart,
    required this.onLogin,
  });

  final VoidCallback onStart;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final desktop = width >= 1200;
      final side = desktop ? 64.0 : 40.0;
      final phone =
          desktop ? 330.0 : math.min(320.0, (width - side * 2 - 40) / 2);
      final onboarding = SkinPhoneMockup(
        width: desktop ? phone * .9 : phone,
        screen: OnboardingHero(
          interactiveKeys: false,
          onStart: onStart,
          onLogin: onLogin,
        ),
      );
      final dashboard = SkinPhoneMockup(
        width: phone,
        screen: const SkinDashboardPreview(),
      );
      final analysis = SkinPhoneMockup(
        width: desktop ? phone * .9 : phone,
        screen: const SkinAnalysisPreview(),
      );

      return SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Padding(
              padding: EdgeInsets.fromLTRB(side, 28, side, 64),
              child: Column(
                children: [
                  Row(
                    children: [
                      const SkinBrandMark(size: 34),
                      const SizedBox(width: 10),
                      const SkinWordmark(fontSize: 22),
                      const Spacer(),
                      TextButton(
                        key: const Key('start-login-link'),
                        onPressed: onLogin,
                        child: const Text('Masuk'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        key: const Key('start-button'),
                        onPressed: onStart,
                        child: const Text('Mulai sekarang'),
                      ),
                    ],
                  ),
                  SizedBox(height: desktop ? 64 : 48),
                  const SkinPill(
                    label: 'Pendamping kulit berbasis AI',
                    icon: Icons.auto_awesome_rounded,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Your personal\nskincare companion',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: SkinTokens.serif,
                      fontSize: desktop ? 76 : 58,
                      height: 1.0,
                      fontWeight: FontWeight.w300,
                      letterSpacing: desktop ? 1 : .5,
                      color: SkinTokens.ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(
                    width: 520,
                    child: Text(
                      'Scan wajah, pantau perubahan setiap minggu, dan baca '
                      'edukasi perawatan yang relevan — dalam satu pendamping '
                      'yang tenang.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: SkinTokens.muted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 300,
                    child: SlideToStartButton(
                        label: 'Glow Guide', onStart: onStart),
                  ),
                  SizedBox(height: desktop ? 72 : 56),
                  if (desktop)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        onboarding,
                        const SizedBox(width: 40),
                        dashboard,
                        const SizedBox(width: 40),
                        analysis,
                      ],
                    )
                  else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        onboarding,
                        const SizedBox(width: 40),
                        dashboard,
                      ],
                    ),
                    const SizedBox(height: 48),
                    analysis,
                  ],
                  const SizedBox(height: 56),
                  const Text(
                    'SkinSight membantu mencatat, bukan mendiagnosis.',
                    style: TextStyle(fontSize: 12, color: SkinTokens.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
