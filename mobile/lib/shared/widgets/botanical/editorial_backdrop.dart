import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import'../../../core/theme/app_colors.dart';
import'./botanical_leaves.dart';

/// Latar editorial pengganti foto yang belum tersedia.
///
/// Mesh gradient sage–aqua–krem, bloom cahaya besar yang buram, dedaunan latar
/// yang sangat buram, satu rumpun lidah buaya sebagai subjek utama, dan grain
/// halus agar gradien tidak bergaris (banding). Komposisi mengikuti ukuran
/// kotak sehingga tetap rapi dari thumbnail hingga layar penuh.
class EditorialBackdrop extends StatelessWidget {
  const EditorialBackdrop({
    super.key,
    this.mirror = false,
    this.showPlant = true,
    this.semanticLabel,
  });

  /// Cerminkan komposisi secara horizontal (variasi untuk layar lain).
  final bool mirror;

  /// Tampilkan rumpun lidah buaya utama.
  final bool showPlant;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: semanticLabel != null,
      excludeSemantics: true,
      child: LayoutBuilder(builder: (context, constraints) {
        final size = constraints.biggest;
        final unit = size.shortestSide;
        Widget art = Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(painter: _MeshPainter()),
            // Dedaunan latar: besar, sangat buram, samar.
            Positioned(
              right: -size.width * .24,
              top: -size.height * .04,
              width: size.width * .8,
              height: size.height * .5,
              child: BotanicalLeaves(
                leafCount: 5,
                spread: 1.5,
                lean: -.55,
                seed: 11,
                blurSigma: unit * .035,
                opacity: .4,
                detailed: false,
              ),
            ),
            if (showPlant)
              Positioned(
                left: size.width * .16,
                right: -size.width * .06,
                top: size.height * .12,
                bottom: size.height * .33,
                // Pangkal rumpun memudar ke kabut, sehingga tanaman tidak
                // tampak "melayang" saat bagian bawahnya tidak tertutup panel.
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (bounds) => LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.white,
                      AppColors.white,
                      AppColors.white.withValues(alpha: 0),
                    ],
                    stops: const [0, .62, .96],
                  ).createShader(bounds),
                  // Tanpa blur: hasil blur akan melewati batas mask di atas.
                  child: BotanicalLeaves(
                    leafCount: 7,
                    spread: 1.7,
                    lean: .05,
                    seed: 3,
                    detailed: unit > 220,
                  ),
                ),
              ),
            const CustomPaint(painter: _GrainPainter()),
          ],
        );
        if (mirror) art = Transform.flip(flipX: true, child: art);
        return ClipRect(child: art);
      }),
    );
  }
}

class _MeshPainter extends CustomPainter {
  const _MeshPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final w = size.width;
    final h = size.height;
    final reach = size.longestSide;

    canvas.drawRect(
      rect,
      Paint()..shader = AppColors.mistGradient.createShader(rect),
    );

    void blob(Offset center, double radius, Color color, double alpha) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.radial(center, radius, [
            color.withValues(alpha: alpha),
            color.withValues(alpha: 0),
          ]),
      );
    }

    blob(Offset(-.05 * w, .06 * h), reach * .6, AppColors.sageMist, .95);
    blob(Offset(1.05 * w, .16 * h), reach * .55, AppColors.aquaSage, .95);
    blob(Offset(.72 * w, .5 * h), reach * .42, AppColors.cream, .95);
    blob(Offset(.08 * w, .84 * h), reach * .45, AppColors.aloe, .16);

    // Bloom: cahaya lembut yang membuat suasana high-key.
    final bloomCenter = Offset(.6 * w, .3 * h);
    final bloomRadius = size.shortestSide * .46;
    canvas.drawCircle(
      bloomCenter,
      bloomRadius,
      Paint()
        ..shader = ui.Gradient.radial(
          bloomCenter,
          bloomRadius,
          [
            AppColors.white.withValues(alpha: .9),
            AppColors.white.withValues(alpha: .4),
            AppColors.white.withValues(alpha: 0),
          ],
          const [0, .45, 1],
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _MeshPainter oldDelegate) => false;
}

/// Grain halus (dithering) agar gradien besar tidak tampak bergaris.
class _GrainPainter extends CustomPainter {
  const _GrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final random = math.Random(42);
    final count = (size.width * size.height / 300).clamp(120, 3200).round();
    final light = <Offset>[];
    final dark = <Offset>[];
    for (var i = 0; i < count; i++) {
      final point = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      (i.isEven ? light : dark).add(point);
    }
    canvas
      ..drawPoints(
        ui.PointMode.points,
        light,
        Paint()
          ..color = AppColors.white.withValues(alpha: .12)
          ..strokeWidth = 1,
      )
      ..drawPoints(
        ui.PointMode.points,
        dark,
        Paint()
          ..color = AppColors.textPrimary.withValues(alpha: .05)
          ..strokeWidth = 1,
      );
  }

  @override
  bool shouldRepaint(covariant _GrainPainter oldDelegate) => false;
}
