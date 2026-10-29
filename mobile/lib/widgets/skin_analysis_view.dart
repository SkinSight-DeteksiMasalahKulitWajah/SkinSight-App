import 'package:flutter/material.dart';

import '../core/app_assets.dart';
import '../theme/skin_theme.dart';
import 'skin_ui.dart';

/// Satu baris metrik analisis: label, nilai tampilan, dan proporsi 0–1.
typedef SkinMetric = ({String label, String value, double fraction});

/// Layar analisis kulit: foto potret dengan jaring pindai bercahaya,
/// tombol kembali + kapsul info di atas, dan panel bawah berisi kapsul
/// metrik serta baris rekomendasi.
class SkinAnalysisView extends StatelessWidget {
  const SkinAnalysisView({
    super.key,
    required this.metrics,
    required this.badge,
    this.photo,
    this.onBack,
    this.backKey,
    this.trailing,
    this.recommendationLabel = 'Rekomendasi perawatan',
    this.onRecommendation,
    this.photoHeight = 420,
    this.radius = 0,
    this.showMesh = true,
    this.emptyMessage,
  });

  /// Foto pengguna; null memakai potret placeholder.
  final ImageProvider? photo;
  final String badge;
  final List<SkinMetric> metrics;
  final VoidCallback? onBack;
  final Key? backKey;
  final Widget? trailing;
  final String recommendationLabel;
  final VoidCallback? onRecommendation;
  final double photoHeight;
  final double radius;
  final bool showMesh;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    const overlap = 36.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: photoHeight + overlap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (photo != null)
                  Image(image: photo!, fit: BoxFit.cover)
                else
                  const SkinPortrait(
                    asset: AppAssets.scanPortrait,
                    alignment: Alignment(.2, -.3),
                    semanticLabel: 'Potret untuk pemindaian kulit',
                    profile: true,
                  ),
                // Pudar lembut ke warna panel di bawah.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00F3F6F4),
                        Color(0x00F3F6F4),
                        Color(0xCCF3F6F4),
                      ],
                      stops: [0, .7, 1],
                    ),
                  ),
                ),
                if (showMesh)
                  // Area rahang → leher.
                  const SkinScanMesh(region: Rect.fromLTWH(.34, .26, .36, .38)),
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      if (onBack != null)
                        SkinCircleButton(
                          key: backKey,
                          tooltip: 'Kembali',
                          icon: Icons.arrow_back_ios_new_rounded,
                          onPressed: onBack,
                        )
                      else
                        const SizedBox(width: 44),
                      Expanded(
                        child: Center(
                          child: SkinGlass(
                            radius: 999,
                            color: SkinTokens.glassStrong,
                            borderColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 9,
                            ),
                            child: Text(
                              badge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: SkinTokens.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                      trailing ?? const SizedBox(width: 44),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: overlap + 14,
                  child: Center(
                    child: Container(
                      width: 34,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .85),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -overlap),
            child: SkinGlass(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(SkinTokens.radiusXl),
              ),
              color: SkinTokens.backgroundLight.withValues(alpha: .86),
              borderColor: Colors.white,
              shadow: false,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SkinDragHandle(),
                  const SizedBox(height: 16),
                  if (metrics.isEmpty && emptyMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(emptyMessage!, style: SkinTokens.caption),
                    ),
                  for (final metric in metrics) ...[
                    SkinMetricPill(
                      label: metric.label,
                      value: metric.value,
                      fraction: metric.fraction,
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 6),
                  _RecommendationRow(
                    label: recommendationLabel,
                    onTap: onRecommendation,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationRow extends StatelessWidget {
  const _RecommendationRow({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(999);
    return Material(
      color: Colors.white.withValues(alpha: .8),
      borderRadius: radius,
      child: InkWell(
        key: const Key('analysis-recommendation'),
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: Colors.white),
          ),
          child: Row(
            children: [
              const SkinIconTile(icon: Icons.auto_fix_high_rounded, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: SkinTokens.ink,
                  ),
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: SkinTokens.shadows,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: SkinTokens.ink,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
