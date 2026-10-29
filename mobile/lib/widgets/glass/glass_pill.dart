import 'package:flutter/widgets.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'glass_card.dart';

/// Kapsul kaca untuk label, tag, atau logo.
///
/// Secara bawaan tanpa blur latar ([blurSigma] = 0) karena biasanya diletakkan
/// di atas panel kaca lain; beri nilai > 0 bila kapsul berdiri sendiri di atas
/// foto.
class GlassPill extends StatelessWidget {
  const GlassPill({
    super.key,
    required this.child,
    this.height = 32,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    this.blurSigma = 0,
    this.fill = AppColors.glassFillStrong,
    this.borderColor = AppColors.white,
    this.shadows = const <BoxShadow>[],
  });

  final Widget child;
  final double height;
  final EdgeInsetsGeometry padding;
  final double blurSigma;
  final Color fill;
  final Color borderColor;
  final List<BoxShadow> shadows;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: GlassCard(
        borderRadius: const BorderRadius.all(Radius.circular(AppRadii.pill)),
        padding: padding,
        blurSigma: blurSigma,
        fill: fill,
        borderColor: borderColor,
        shadows: shadows,
        child: Center(widthFactor: 1, child: child),
      ),
    );
  }
}
