import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/skin_theme.dart';
import '../../widgets/slide_to_start_button.dart';
import 'onboarding_motion.dart';
import 'onboarding_strings.dart';

/// Konten bawah layar pembuka: tag "Glow On the Go", headline, CTA geser
/// "Glow Guide", dan tautan masuk. Tanpa panel tebal — teks duduk langsung
/// di atas pudar mist, persis seperti referensi.
class OnboardingPanel extends StatelessWidget {
  const OnboardingPanel({
    super.key,
    required this.controller,
    required this.onStart,
    required this.onLogin,
    this.interactiveKeys = true,
  });

  final Animation<double> controller;
  final VoidCallback onStart;
  final VoidCallback onLogin;

  /// False untuk salinan di dalam mockup agar key tidak ganda.
  final bool interactiveKeys;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final short = size.height < 640;
    final headlineSize =
        (math.min(size.width, 480) * .074).clamp(23.0, 32.0) - (short ? 2 : 0);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        math.max(bottomInset, AppSpacing.sm) + AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          StaggeredEntry(
            controller: controller,
            step: OnboardingTimeline.tag,
            child: const _TagPill(),
          ),
          SizedBox(height: short ? AppSpacing.sm : AppSpacing.md),
          StaggeredEntry(
            controller: controller,
            step: OnboardingTimeline.headline,
            child: _Headline(fontSize: headlineSize),
          ),
          SizedBox(height: short ? AppSpacing.lg : AppSpacing.xl),
          StaggeredEntry(
            controller: controller,
            step: OnboardingTimeline.cta,
            child: SlideToStartButton(
              key: interactiveKeys ? const Key('start-button') : null,
              label: OnboardingStrings.start,
              semanticHint: OnboardingStrings.startHint,
              onStart: onStart,
              height: short ? 58 : 64,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          StaggeredEntry(
            controller: controller,
            step: OnboardingTimeline.link,
            child: _LoginLink(
              onLogin: onLogin,
              buttonKey: interactiveKeys ? const Key('start-login-link') : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: .62),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.white),
        boxShadow: const [
          BoxShadow(
            color: AppColors.glassShadow,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        OnboardingStrings.tag,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: AppColors.textPrimary.withValues(alpha: .78),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: .1,
            ),
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.fontSize});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Baris 1: sans tebal. Baris 2: serif miring tipis (sedikit lebih besar
    // untuk mengimbangi x-height Cormorant), diikuti panah kecil sage.
    final lead = textTheme.headlineLarge!.copyWith(
      fontSize: fontSize,
      height: 1.12,
      fontWeight: FontWeight.w700,
      letterSpacing: -.6,
      color: AppColors.textPrimary,
    );
    final accent = TextStyle(
      fontFamily: SkinTokens.serif,
      fontSize: fontSize * 1.18,
      height: 1.1,
      fontWeight: FontWeight.w300,
      fontStyle: FontStyle.italic,
      color: AppColors.textPrimary,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          label:
              '${OnboardingStrings.headlineLead} ${OnboardingStrings.headlineAccent}',
          excludeSemantics: true,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '${OnboardingStrings.headlineLead}\n', style: lead),
                TextSpan(
                  text: '${OnboardingStrings.headlineAccent} ',
                  style: accent,
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Icon(
                    Icons.south_rounded,
                    size: fontSize * .82,
                    color: AppColors.aloe,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          OnboardingStrings.subtitle,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyMedium!.copyWith(
            fontSize: 13.5,
            height: 1.5,
            color: AppColors.textSecondaryOnGlass,
          ),
        ),
      ],
    );
  }
}

class _LoginLink extends StatelessWidget {
  const _LoginLink({required this.onLogin, this.buttonKey});

  final VoidCallback onLogin;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    final body = Theme.of(context).textTheme.bodyMedium!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            OnboardingStrings.haveAccount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: body.copyWith(color: AppColors.textSecondaryOnGlass),
          ),
        ),
        TextButton(
          key: buttonKey,
          onPressed: onLogin,
          style: TextButton.styleFrom(
            minimumSize: const Size.square(AppSpacing.touchTarget),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          ),
          child: Text(
            OnboardingStrings.login,
            style: body.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.textPrimary.withValues(alpha: .35),
              decorationThickness: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}
