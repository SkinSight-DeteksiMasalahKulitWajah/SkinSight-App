import 'package:flutter/material.dart';

import'../../../core/app_assets.dart';
import'../../auth/models/auth_session.dart';
import'../../../core/theme/skin_theme.dart';
import'../../../shared/widgets/skin_page_background.dart';
import'../../../shared/widgets/skin_3d.dart';
import'../../../shared/widgets/design_system/skin_ui.dart';

class SkinOnboardingPage extends StatefulWidget {
  const SkinOnboardingPage({super.key});

  @override
  State<SkinOnboardingPage> createState() => _SkinOnboardingPageState();
}

class _SkinOnboardingPageState extends State<SkinOnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  static const _slides = <_OnboardingSlideData>[
    _OnboardingSlideData(
      imagePath: AppAssets.onboarding1,
      eyebrow: 'ANALISIS VISUAL',
      icon: Icons.center_focus_strong_rounded,
      title: 'Kenali kondisi kulitmu',
      body: 'Ambil foto wajah untuk melihat ringkasan temuan visual kulitmu.',
    ),
    _OnboardingSlideData(
      imagePath: AppAssets.onboarding2,
      eyebrow: 'SKIN JOURNEY',
      icon: Icons.timeline_rounded,
      title: 'Pantau perjalanan kulitmu',
      body:
          'Simpan hasil scan dan lihat perkembangan kulitmu dari waktu ke waktu.',
    ),
    _OnboardingSlideData(
      imagePath: AppAssets.onboarding3,
      eyebrow: 'CHECK-IN MINGGUAN',
      icon: Icons.edit_calendar_rounded,
      title: 'Check-in rutin lebih mudah',
      body:
          'Isi check-in singkat dan tambah foto pemantauan untuk membantu perjalanan kulitmu.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    AuthSession.instance.completeOnboarding();
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
  }

  void _next() {
    if (_index == _slides.length - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _slides.length - 1;

    return Scaffold(
      key: const Key('onboarding-page'),
      backgroundColor: SkinTokens.background,
      body: SkinPageBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: SkinTokens.maxWidth),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 8, 12, 0),
                    child: Row(
                      children: [
                        const SkinBrandMark(size: 28),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: SkinWordmark(fontSize: 17),
                            ),
                          ),
                        ),
                        AnimatedOpacity(
                          duration: SkinTokens.fast,
                          opacity: isLast ? 0 : 1,
                          child: TextButton(
                            key: const Key('onboarding-skip'),
                            onPressed: isLast ? null : _finish,
                            style: TextButton.styleFrom(
                              foregroundColor: SkinTokens.muted,
                            ),
                            child: const Text('Lewati'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      key: const Key('onboarding-slides'),
                      controller: _controller,
                      itemCount: _slides.length,
                      onPageChanged: (value) => setState(() => _index = value),
                      itemBuilder: (context, index) =>
                          _OnboardingSlide(data: _slides[index]),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var index = 0; index < _slides.length; index++)
                        AnimatedContainer(
                          key: Key('onboarding-dot-$index'),
                          duration: SkinTokens.medium,
                          curve: Curves.easeOutCubic,
                          width: index == _index ? 26 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: index == _index
                                ? SkinTokens.primary
                                : Colors.white,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const Key('onboarding-next'),
                        onPressed: _next,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(58),
                          padding: const EdgeInsets.fromLTRB(24, 0, 8, 0),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                isLast ? 'Mulai' : 'Berikutnya',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Container(
                              width: 42,
                              height: 42,
                              decoration: const BoxDecoration(
                                color: Color(0x24FFFFFF),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isLast
                                    ? Icons.check_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.data});

  final _OnboardingSlideData data;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final compact = screenHeight < 650;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, compact ? 4 : 10, 24, compact ? 8 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SkinReveal(
              offset: 24,
              child: SkinGlass(
                radius: 36,
                color: SkinTokens.glass,
                borderColor: Colors.white,
                borderWidth: 2,
                shadows: SkinTokens.shadowsLifted,
                // Di atas latar gradien; ilustrasi di dalamnya melayang, jadi
                // blur latar akan dihitung ulang setiap frame tanpa beda
                // visual.
                blur: 0,
                child: SizedBox.expand(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment(0, -.1),
                            radius: .85,
                            colors: [
                              Color(0xFFFFFFFF),
                              Color(0x99E3EEE9),
                              Color(0x00DCEAE5),
                            ],
                            stops: [0, .55, 1],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Skin3D(
                          data.imagePath,
                          key: Key('onboarding-image-${data.imagePath}'),
                          float: true,
                          floatDistance: 6,
                          semanticLabel: data.title,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: compact ? 16 : 24),
          SkinPill(label: data.eyebrow, icon: data.icon),
          SizedBox(height: compact ? 8 : 12),
          Text(
            data.title,
            key: Key('onboarding-title-${data.imagePath}'),
            style: TextStyle(
              fontFamily: SkinTokens.serif,
              color: SkinTokens.ink,
              fontSize: compact ? 30 : 36,
              fontWeight: FontWeight.w500,
              height: 1.05,
            ),
          ),
          SizedBox(height: compact ? 6 : 10),
          Text(
            data.body,
            key: Key('onboarding-body-${data.imagePath}'),
            style: TextStyle(
              color: SkinTokens.muted,
              fontSize: compact ? 14.5 : 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlideData {
  const _OnboardingSlideData({
    required this.imagePath,
    required this.eyebrow,
    required this.icon,
    required this.title,
    required this.body,
  });

  final String imagePath;
  final String eyebrow;
  final IconData icon;
  final String title;
  final String body;
}
