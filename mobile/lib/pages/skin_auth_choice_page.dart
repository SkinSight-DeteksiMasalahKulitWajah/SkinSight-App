import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_assets.dart';
import '../data/auth_service.dart';
import '../models/auth_session.dart';
import '../theme/skin_theme.dart';
import '../widgets/skin_ui.dart';

class SkinAuthChoicePage extends StatelessWidget {
  const SkinAuthChoicePage({super.key});

  Future<void> _registerWithGoogle(BuildContext context) async {
    try {
      await context.read<AuthService>().signInWithGoogle();
      if (!context.mounted) return;
      AuthSession.instance.signIn();
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/onboarding', (_) => false);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SkinTokens.backgroundLight,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: SkinTokens.maxWidth),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final panelTop = constraints.maxHeight * .46;
              return SingleChildScrollView(
                key: const Key('auth-choice-scroll'),
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        right: 0,
                        height: panelTop + 48,
                        child: const _AuthChoiceHero(),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: panelTop),
                          SkinReveal(
                            offset: 40,
                            child: _AuthChoicePanel(
                              minHeight: constraints.maxHeight - panelTop,
                              onGoogle: () => _registerWithGoogle(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AuthChoiceHero extends StatelessWidget {
  const _AuthChoiceHero();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const SkinPortrait(
          asset: AppAssets.heroPortrait,
          alignment: Alignment(.3, -.42),
          semanticLabel: 'Potret model dengan kulit bercahaya',
        ),
        Positioned(
          left: -70,
          bottom: 34,
          width: 250,
          height: 158,
          child: Transform.rotate(
            angle: .32,
            child: const SkinAloe(),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x33FFFFFF),
                Colors.transparent,
                Color(0x66F3F6F4)
              ],
              stops: [0, .5, 1],
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  SkinCircleButton(
                    key: const Key('auth-choice-back'),
                    tooltip: 'Kembali',
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  const SkinGlass(
                    radius: 999,
                    color: SkinTokens.glassStrong,
                    borderColor: Colors.white,
                    padding: EdgeInsets.fromLTRB(6, 6, 14, 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SkinBrandMark(size: 28),
                        SizedBox(width: 8),
                        SkinWordmark(fontSize: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthChoicePanel extends StatelessWidget {
  const _AuthChoicePanel({
    required this.onGoogle,
    required this.minHeight,
  });

  final VoidCallback onGoogle;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 700;
    return SkinGlass(
      key: const Key('auth-choice-panel'),
      borderRadius: const BorderRadius.vertical(
          top: Radius.circular(SkinTokens.radiusXl)),
      color: SkinTokens.backgroundLight.withValues(alpha: .9),
      borderColor: Colors.white,
      shadows: const [
        BoxShadow(
          color: Color(0x1A1F2A27),
          blurRadius: 30,
          offset: Offset(0, -8),
        ),
      ],
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        padding: EdgeInsets.fromLTRB(
          compact ? 20 : 24,
          12,
          compact ? 20 : 24,
          10 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SkinDragHandle(),
            SizedBox(height: compact ? 14 : 18),
            Text(
              'Mulai bersama SkinSight',
              style: TextStyle(
                fontFamily: SkinTokens.serif,
                color: SkinTokens.ink,
                fontSize: compact ? 30 : 34,
                height: 1.05,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Buat akun untuk menyimpan hasil scan dan memantau perjalanan kulitmu.',
              style: SkinTokens.caption,
            ),
            SizedBox(height: compact ? 16 : 20),
            OutlinedButton(
              key: const Key('auth-google'),
              onPressed: onGoogle,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SkinGoogleMark(),
                    SizedBox(width: 12),
                    Text('Lanjut dengan Google'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              key: const Key('auth-email'),
              onPressed: () => Navigator.of(context).pushNamed('/register'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
              ),
              icon: const Icon(Icons.mail_outline_rounded),
              label: const Text('Lanjut dengan Email'),
            ),
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Sudah punya akun?', style: SkinTokens.caption),
                TextButton(
                  key: const Key('auth-login'),
                  onPressed: () => Navigator.of(context).pushNamed('/login'),
                  child: const Text('Masuk'),
                ),
              ],
            ),
            const _AuthLegalLinks(),
          ],
        ),
      ),
    );
  }
}

class _AuthLegalLinks extends StatelessWidget {
  const _AuthLegalLinks();

  @override
  Widget build(BuildContext context) {
    final linkStyle = TextButton.styleFrom(
      minimumSize: const Size(0, 36),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      textStyle: Theme.of(context)
          .textTheme
          .labelLarge!
          .copyWith(fontSize: 12.5, fontWeight: FontWeight.w700),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      decoration: BoxDecoration(
        color: SkinTokens.glass,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SkinTokens.glassBorder),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded,
                  size: 14, color: SkinTokens.muted),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Data kulitmu diproses sesuai ketentuan berikut.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: SkinTokens.muted, fontSize: 12),
                ),
              ),
            ],
          ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 2,
            children: [
              TextButton(
                key: const Key('auth-open-privacy'),
                style: linkStyle,
                onPressed: () => Navigator.of(context).pushNamed('/privacy'),
                child: const Text('Kebijakan Privasi'),
              ),
              TextButton(
                key: const Key('auth-open-terms'),
                style: linkStyle,
                onPressed: () => Navigator.of(context).pushNamed('/terms'),
                child: const Text('Syarat & Ketentuan'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
