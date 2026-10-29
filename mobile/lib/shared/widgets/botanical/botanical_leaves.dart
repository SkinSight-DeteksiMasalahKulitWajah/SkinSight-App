import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import'../../../core/theme/app_colors.dart';

/// Rumpun daun lidah buaya (aloe) yang digambar dengan [CustomPainter].
///
/// Setiap daun berupa path runcing yang sedikit melengkung, bergradien dari
/// [baseColor] (pangkal) ke [tipColor] (ujung), dengan kanal tengah yang lebih
/// gelap, kilau tipis di tulang daun, tepi bercahaya, serta gerigi & bintik
/// halus. Rumpun tumbuh dari tengah-bawah kotak widget, jadi beri ukuran lewat
/// induknya (`SizedBox`, `Positioned`, dsb.).
class BotanicalLeaves extends StatelessWidget {
  const BotanicalLeaves({
    super.key,
    this.leafCount = 5,
    this.spread = 1.2,
    this.lean = 0,
    this.seed = 1,
    this.baseColor = AppColors.aloe,
    this.tipColor = AppColors.aquaSage,
    this.blurSigma = 0,
    this.opacity = 1,
    this.detailed = true,
    this.lightFromLeft = false,
  });

  /// Jumlah daun dalam rumpun.
  final int leafCount;

  /// Sudut sebaran total daun, dalam radian.
  final double spread;

  /// Kemiringan seluruh rumpun (radian; positif = condong ke kanan).
  final double lean;

  /// Benih acak agar variasi panjang & sudut daun stabil di setiap frame.
  final int seed;
  final Color baseColor;
  final Color tipColor;

  /// Blur kedalaman ruang (depth of field). 0 = tajam.
  final double blurSigma;
  final double opacity;

  /// Gerigi & bintik daun. Matikan untuk ukuran sangat kecil atau lapisan
  /// yang sangat buram.
  final bool detailed;

  /// Arah datang cahaya; sisi sebaliknya mendapat bayangan kanal.
  final bool lightFromLeft;

  @override
  Widget build(BuildContext context) {
    Widget leaves = CustomPaint(
      size: Size.infinite,
      painter: _AloeClusterPainter(
        leafCount: leafCount,
        spread: spread,
        lean: lean,
        seed: seed,
        baseColor: baseColor,
        tipColor: tipColor,
        detailed: detailed,
        lightFromLeft: lightFromLeft,
      ),
    );
    if (blurSigma > 0) {
      leaves = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: blurSigma,
          sigmaY: blurSigma,
          tileMode: TileMode.decal,
        ),
        child: leaves,
      );
    }
    if (opacity < 1) leaves = Opacity(opacity: opacity, child: leaves);
    return IgnorePointer(child: RepaintBoundary(child: leaves));
  }
}

class _Leaf {
  const _Leaf({
    required this.angle,
    required this.length,
    required this.width,
    required this.droop,
    required this.depth,
  });

  final double angle;
  final double length;
  final double width;

  /// Lengkung ujung daun ke samping, relatif terhadap panjang daun.
  final double droop;

  /// 0 = daun tengah (paling depan), 1 = daun terluar (paling belakang).
  final double depth;
}

class _AloeClusterPainter extends CustomPainter {
  const _AloeClusterPainter({
    required this.leafCount,
    required this.spread,
    required this.lean,
    required this.seed,
    required this.baseColor,
    required this.tipColor,
    required this.detailed,
    required this.lightFromLeft,
  });

  final int leafCount;
  final double spread;
  final double lean;
  final int seed;
  final Color baseColor;
  final Color tipColor;
  final bool detailed;
  final bool lightFromLeft;

  static const _samples = 28;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || leafCount <= 0) return;
    // Sudut pangkal daun yang miring bisa sedikit keluar dari kotak; klip
    // agar mask/pudar milik induk (ShaderMask) menutup seluruh gambar.
    canvas.clipRect(Offset.zero & size);
    final random = math.Random(seed);
    final base = Offset(size.width / 2, size.height);
    final leaves = <_Leaf>[];
    for (var i = 0; i < leafCount; i++) {
      final t = leafCount == 1 ? .5 : i / (leafCount - 1);
      final centered = t - .5;
      final angle = lean + centered * spread + (random.nextDouble() - .5) * .1;
      // Daun tengah paling panjang, daun tepi lebih pendek.
      final reach = .62 + .38 * math.cos(centered * math.pi);
      var length = size.height * .97 * reach * (.9 + random.nextDouble() * .1);
      // Jaga agar ujung daun tetap di dalam lebar kotak.
      final sideways = math.max(math.sin(angle.abs()), .15);
      length = math.min(length, size.width * .49 / sideways);
      leaves.add(_Leaf(
        angle: angle,
        length: length,
        width: length * (.15 + random.nextDouble() * .03),
        droop: angle.sign * (.05 + angle.abs() * .14),
        depth: (centered.abs() * 2).clamp(0.0, 1.0),
      ));
    }
    // Daun terluar digambar lebih dulu agar berada di belakang.
    leaves.sort((a, b) => b.depth.compareTo(a.depth));
    for (final leaf in leaves) {
      _paintLeaf(canvas, base, leaf, random);
    }
  }

  void _paintLeaf(Canvas canvas, Offset base, _Leaf leaf, math.Random random) {
    final direction = Offset(math.sin(leaf.angle), -math.cos(leaf.angle));
    final side = Offset(-direction.dy, direction.dx);
    final tip =
        base + direction * leaf.length + side * (leaf.droop * leaf.length);
    final control = base + direction * (leaf.length * .55);

    Offset pointAt(double s) {
      final u = 1 - s;
      return base * (u * u) + control * (2 * u * s) + tip * (s * s);
    }

    Offset tangentAt(double s) {
      final d = (control - base) * (2 * (1 - s)) + (tip - control) * (2 * s);
      final length = d.distance;
      return length == 0 ? direction : d / length;
    }

    double halfWidth(double s) =>
        leaf.width / 2 * math.pow(1 - s, .85) * (1 + .4 * s);

    final center = <Offset>[];
    final left = <Offset>[];
    final right = <Offset>[];
    final normals = <Offset>[];
    for (var k = 0; k <= _samples; k++) {
      final s = k / _samples;
      final c = pointAt(s);
      final tangent = tangentAt(s);
      final normal = Offset(-tangent.dy, tangent.dx);
      final hw = halfWidth(s);
      center.add(c);
      normals.add(normal);
      left.add(c - normal * hw);
      right.add(c + normal * hw);
    }

    final outline = Path()..moveTo(left.first.dx, left.first.dy);
    _smoothTo(outline, left);
    _smoothTo(outline, right.reversed.toList());
    outline.close();

    // 1. Isi: gradien sepanjang daun; daun belakang sedikit lebih gelap.
    final dim = .1 + leaf.depth * .2;
    canvas.drawPath(
      outline,
      Paint()
        ..shader = ui.Gradient.linear(
          base,
          tip,
          [
            Color.lerp(baseColor, AppColors.aloeShade, .3 + dim)!,
            Color.lerp(baseColor, AppColors.aloeShade, dim)!,
            Color.lerp(tipColor, baseColor, dim * .6)!,
          ],
          const [0, .38, 1],
        ),
    );

    // 2. Kanal: sisi yang membelakangi cahaya lebih gelap.
    final shadedEdge = lightFromLeft ? right : left;
    final channel = Path()..moveTo(center.first.dx, center.first.dy);
    _smoothTo(channel, center);
    _smoothTo(channel, shadedEdge.reversed.toList());
    channel.close();
    canvas.drawPath(
      channel,
      Paint()
        ..shader = ui.Gradient.linear(
          base,
          tip,
          [
            AppColors.aloeShade.withValues(alpha: .4),
            AppColors.aloeShade.withValues(alpha: .1),
          ],
        ),
    );

    // 3. Kilau tipis di tulang daun, sedikit ke arah cahaya.
    final litSign = lightFromLeft ? -1.0 : 1.0;
    final ridge = Path();
    for (var k = 2; k <= (_samples * .88).round(); k++) {
      final s = k / _samples;
      final p = center[k] + normals[k] * (halfWidth(s) * .3 * litSign);
      if (k == 2) {
        ridge.moveTo(p.dx, p.dy);
      } else {
        ridge.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      ridge,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(.6, leaf.width * .05)
        ..shader = ui.Gradient.linear(
          base,
          tip,
          [
            AppColors.white.withValues(alpha: .34),
            AppColors.white.withValues(alpha: 0),
          ],
        ),
    );

    // 4. Tepi bercahaya.
    canvas.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, leaf.width * .02)
        ..color = AppColors.aloeHighlight.withValues(alpha: .35),
    );

    if (!detailed || leaf.width < 10) return;

    // 5. Gerigi kecil di kedua tepi, condong ke arah ujung daun.
    final teeth = Path();
    final toothSize = leaf.width * .045;
    for (var s = .12; s <= .82; s += .07) {
      final k = (s * _samples).round();
      final tangent = tangentAt(s);
      for (final (edge, outward) in [
        (left[k], -normals[k]),
        (right[k], normals[k]),
      ]) {
        final from = edge - tangent * toothSize;
        final apex =
            edge + outward * (toothSize * 1.2) + tangent * (toothSize * .6);
        final to = edge + tangent * toothSize;
        teeth
          ..moveTo(from.dx, from.dy)
          ..lineTo(apex.dx, apex.dy)
          ..lineTo(to.dx, to.dy)
          ..close();
      }
    }
    canvas.drawPath(
      teeth,
      Paint()..color = AppColors.aloeHighlight.withValues(alpha: .8),
    );

    // 6. Bintik khas lidah buaya di separuh bawah daun.
    if (leaf.width < 14) return;
    final speckle = Paint()
      ..color = AppColors.aloeHighlight.withValues(alpha: .28);
    for (var i = 0; i < 6; i++) {
      final s = .1 + random.nextDouble() * .5;
      final k = (s * _samples).round();
      final across = (random.nextDouble() - .5) * 1.1;
      final p = center[k] + normals[k] * (halfWidth(s) * across);
      canvas.drawCircle(
        p,
        leaf.width * .028 * (.6 + random.nextDouble() * .8),
        speckle,
      );
    }
  }

  /// Menyambung titik-titik dengan kurva kuadratik melalui titik tengah,
  /// sehingga tepi daun mulus tanpa sudut patah.
  static void _smoothTo(Path path, List<Offset> points) {
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final mid = Offset.lerp(previous, points[i], .5)!;
      path.quadraticBezierTo(previous.dx, previous.dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
  }

  @override
  bool shouldRepaint(covariant _AloeClusterPainter oldDelegate) =>
      oldDelegate.leafCount != leafCount ||
      oldDelegate.spread != spread ||
      oldDelegate.lean != lean ||
      oldDelegate.seed != seed ||
      oldDelegate.baseColor != baseColor ||
      oldDelegate.tipColor != tipColor ||
      oldDelegate.detailed != detailed ||
      oldDelegate.lightFromLeft != lightFromLeft;
}
