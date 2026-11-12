import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/skin_theme.dart';
import '../../features/scan/models/skin_analysis.dart';

/// Overlay visual untuk menggantikan jaring-jaring statis.
/// Menampilkan:
/// 1. Tanda Face Detection (FACE ROI frame di sekeliling area wajah).
/// 2. Lingkaran deteksi bercahaya & label untuk setiap temuan (Acne, PIH, Wrinkle, Redness, dll).
/// 3. Tombol toggle untuk melihat foto polos vs tanda deteksi.
class SkinFaceDetectionOverlay extends StatefulWidget {
  const SkinFaceDetectionOverlay({
    super.key,
    required this.faceRect,
    required this.visualBoxes,
    this.imageWidth,
    this.imageHeight,
    this.initialShowMarkers = true,
  });

  /// Koordinat area wajah terdeteksi (0..1 terhadap dimensi foto asli).
  final Rect? faceRect;

  /// Daftar kotak/lingkaran deteksi individual (0..1 terhadap dimensi foto asli).
  final List<SkinVisualBox> visualBoxes;

  /// Lebar foto asli (px).
  final int? imageWidth;

  /// Tinggi foto asli (px).
  final int? imageHeight;

  /// Apakah penanda aktif saat pertama kali dibuka.
  final bool initialShowMarkers;

  @override
  State<SkinFaceDetectionOverlay> createState() =>
      _SkinFaceDetectionOverlayState();
}

class _SkinFaceDetectionOverlayState extends State<SkinFaceDetectionOverlay>
    with SingleTickerProviderStateMixin {
  late bool _showMarkers;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _showMarkers = widget.initialShowMarkers;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.loops(context)) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.value = 0.5;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  static Color colorForLabel(String label) {
    return switch (label) {
      'Acne' => const Color(0xFF00E5FF), // Cyan tajam
      'PIH' => const Color(0xFFC084FC), // Ungu muda
      'Dark Circle' => const Color(0xFFFB923C), // Oranye hangat
      'Redness' => const Color(0xFFF87171), // Merah rose lembut
      'Wrinkle' => const Color(0xFF4ADE80), // Hijau emerald
      _ => const Color(0xFF38BDF8),
    };
  }

  static String titleForLabel(String label) {
    return switch (label) {
      'Acne' => 'Acne',
      'PIH' => 'PIH',
      'Dark Circle' => 'Dark Circle',
      'Redness' => 'Redness',
      'Wrinkle' => 'Wrinkle',
      _ => label,
    };
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final containerW = constraints.maxWidth;
        final containerH = constraints.maxHeight;

        // Gunakan rasio aspek foto asli, atau fallback 3:4 (kamera selfie standar)
        final imgW = (widget.imageWidth ?? 3).toDouble();
        final imgH = (widget.imageHeight ?? 4).toDouble();

        // Skala BoxFit.cover yang identik dengan widget Image
        final scale = math.max(containerW / imgW, containerH / imgH);
        final scaledW = imgW * scale;
        final scaledH = imgH * scale;
        final offsetX = (containerW - scaledW) / 2.0;
        final offsetY = (containerH - scaledH) / 2.0;

        Rect toScreen(Rect norm) {
          return Rect.fromLTRB(
            offsetX + norm.left * scaledW,
            offsetY + norm.top * scaledH,
            offsetX + norm.right * scaledW,
            offsetY + norm.bottom * scaledH,
          );
        }

        final screenFace =
            widget.faceRect != null ? toScreen(widget.faceRect!) : null;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Lapisan Penanda (Face ROI + Lingkaran Deteksi)
            if (_showMarkers) ...[
              // Lukisan Tanda Face ROI & Lingkaran
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size(containerW, containerH),
                    painter: _DetectionPainter(
                      screenFace: screenFace,
                      visualBoxes: widget.visualBoxes,
                      toScreen: toScreen,
                      pulse: _pulseAnimation.value,
                    ),
                  );
                },
              ),

              // Label & Badge HTML/Flutter Overlay (tajam dan mudah dibaca)
              if (screenFace != null)
                Positioned(
                  left: math.max(12.0, screenFace.left + 8),
                  top: math.max(16.0, screenFace.top - 26),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD600),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.face_retouching_natural_rounded,
                          size: 13,
                          color: Colors.black87,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'FACE ROI',
                          style: TextStyle(
                            fontFamily: SkinTokens.sans,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Chip info jika wajah terdeteksi tetapi tidak ada temuan lesi
              if (screenFace != null && widget.visualBoxes.isEmpty)
                Positioned(
                  left: math.max(16.0, screenFace.left),
                  right: math.max(16.0, containerW - screenFace.right),
                  bottom: math.max(
                      50.0, containerH - screenFace.bottom + 8),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: SkinTokens.aqua.withValues(alpha: 0.8),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 14, color: SkinTokens.aqua),
                          SizedBox(width: 6),
                          Text(
                            'Area Wajah Terverifikasi · Kulit Bersih',
                            style: TextStyle(
                              fontFamily: SkinTokens.sans,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Label Chips untuk setiap lingkaran temuan
              for (final box in widget.visualBoxes)
                _buildBoxLabel(toScreen(box.normalizedRect), box, containerW,
                    containerH),
            ],

            // Tombol Kontrol Toggle (Pojok Kanan Bawah Foto)
            Positioned(
              right: 14,
              bottom: 46,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _showMarkers = !_showMarkers),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.68),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: _showMarkers
                            ? const Color(0xFFFFD600)
                            : Colors.white.withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showMarkers
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          size: 14,
                          color: _showMarkers
                              ? const Color(0xFFFFD600)
                              : Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _showMarkers ? 'Deteksi Aktif' : 'Foto Polos',
                          style: TextStyle(
                            fontFamily: SkinTokens.sans,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _showMarkers
                                ? const Color(0xFFFFD600)
                                : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBoxLabel(
      Rect rect, SkinVisualBox box, double containerW, double containerH) {
    final color = colorForLabel(box.label);
    final title = titleForLabel(box.label);
    final scoreStr = box.score > 0 ? box.score.toStringAsFixed(2) : '';
    final text = scoreStr.isNotEmpty ? '$title $scoreStr' : title;

    final center = rect.center;
    final radius = math.max(math.max(rect.width, rect.height) / 2.0, 16.0);
    final left = (center.dx - 28.0).clamp(8.0, containerW - 74.0);
    final top = (center.dy - radius - 20.0).clamp(12.0, containerH - 30.0);

    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: SkinTokens.sans,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter yang melukis Face ROI dan lingkaran penanda deteksi.
class _DetectionPainter extends CustomPainter {
  const _DetectionPainter({
    required this.screenFace,
    required this.visualBoxes,
    required this.toScreen,
    required this.pulse,
  });

  final Rect? screenFace;
  final List<SkinVisualBox> visualBoxes;
  final Rect Function(Rect) toScreen;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Lukis Tanda Face ROI (kotak dengan sudut aksen khas vision detection)
    if (screenFace != null) {
      _paintFaceRoi(canvas, screenFace!);
    }

    // 2. Lukis Lingkaran Deteksi untuk setiap temuan
    for (final box in visualBoxes) {
      final rect = toScreen(box.normalizedRect);
      final color = _SkinFaceDetectionOverlayState.colorForLabel(box.label);
      _paintDetectionCircle(canvas, rect, color);
    }
  }

  void _paintFaceRoi(Canvas canvas, Rect rect) {
    const roiColor = Color(0xFFFFD600); // Yellow gold khas prototipe
    final borderPaint = Paint()
      ..color = roiColor.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    // Garis perimeter halus
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      borderPaint,
    );

    // 4 Sudut L-bracket tebal
    final cornerPaint = Paint()
      ..color = roiColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    const cornerLen = 22.0;

    // Kiri atas
    canvas.drawLine(
        rect.topLeft, rect.topLeft + const Offset(cornerLen, 0), cornerPaint);
    canvas.drawLine(
        rect.topLeft, rect.topLeft + const Offset(0, cornerLen), cornerPaint);

    // Kanan atas
    canvas.drawLine(
        rect.topRight, rect.topRight - const Offset(cornerLen, 0), cornerPaint);
    canvas.drawLine(
        rect.topRight, rect.topRight + const Offset(0, cornerLen), cornerPaint);

    // Kiri bawah
    canvas.drawLine(rect.bottomLeft,
        rect.bottomLeft + const Offset(cornerLen, 0), cornerPaint);
    canvas.drawLine(rect.bottomLeft,
        rect.bottomLeft - const Offset(0, cornerLen), cornerPaint);

    // Kanan bawah
    canvas.drawLine(rect.bottomRight,
        rect.bottomRight - const Offset(cornerLen, 0), cornerPaint);
    canvas.drawLine(rect.bottomRight,
        rect.bottomRight - const Offset(0, cornerLen), cornerPaint);
  }

  void _paintDetectionCircle(Canvas canvas, Rect rect, Color color) {
    final center = rect.center;
    final baseRadius =
        math.max(math.max(rect.width, rect.height) / 2.0, 16.0);
    final pulseRadius = baseRadius + (pulse * 3.5);

    // Outer glow pulse
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.18 + (pulse * 0.12))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, pulseRadius, glowPaint);

    // Inner subtle wash
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, baseRadius, fillPaint);

    // Lingkaran utama (stroke tebal jelas)
    final ringPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawCircle(center, baseRadius, ringPaint);

    // Titik pusat target
    final centerDotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2.5, centerDotPaint);
  }

  @override
  bool shouldRepaint(covariant _DetectionPainter oldDelegate) {
    return oldDelegate.pulse != pulse ||
        oldDelegate.screenFace != screenFace ||
        oldDelegate.visualBoxes != visualBoxes;
  }
}
