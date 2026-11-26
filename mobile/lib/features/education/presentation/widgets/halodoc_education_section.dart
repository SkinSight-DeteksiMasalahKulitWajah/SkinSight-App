import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/skin_theme.dart';
import '../../../../shared/widgets/design_system/skin_ui.dart';
import '../../data/halodoc_education.dart';
import '../../data/skin_scan_education.dart';

/// Daftar accordion edukasi (sumber Halodoc) untuk temuan scan pengguna.
/// Tanpa temuan yang dikenali, semua topik ditampilkan sebagai edukasi umum.
class HalodocEducationSection extends StatelessWidget {
  const HalodocEducationSection({super.key, required this.findings});

  final List<String> findings;

  @override
  Widget build(BuildContext context) {
    final matched = findings.where(halodocEducation.containsKey).toSet().toList();
    final general = matched.isEmpty;
    final keys = general ? halodocEducation.keys.toList() : matched;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SkinSectionTitle(
          title: 'Edukasi masalah kulitmu',
          subtitle: general
              ? 'Tidak ada temuan khusus. Pelajari edukasi umum dari Halodoc.'
              : 'Ringkasan dari Halodoc sesuai temuan scan. Ketuk untuk membuka.',
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < keys.length; i++) ...[
          _EducationAccordion(
            key: Key('halodoc-edu-${keys[i]}'),
            findingKey: keys[i],
            initiallyExpanded: !general && i == 0,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _EducationAccordion extends StatelessWidget {
  const _EducationAccordion({
    super.key,
    required this.findingKey,
    required this.initiallyExpanded,
  });

  final String findingKey;
  final bool initiallyExpanded;

  Future<void> _openArticle(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    var opened = false;
    try {
      opened = await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
    } on Object {
      opened = false;
    }
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka artikel Halodoc.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final edu = halodocEducation[findingKey]!;
    final color = findingColor(findingKey);

    return SkinCard(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(SkinTokens.radiusLg),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          iconColor: SkinTokens.primary,
          collapsedIconColor: SkinTokens.muted,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .14),
              shape: BoxShape.circle,
            ),
            child: Icon(findingIcon(findingKey), color: color, size: 20),
          ),
          title: Text(
            edu.title,
            style: const TextStyle(
              color: SkinTokens.ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: const Text(
            'Sumber: Halodoc',
            style: TextStyle(color: SkinTokens.muted, fontSize: 12),
          ),
          children: [
            Text(
              edu.summary,
              style: const TextStyle(
                color: SkinTokens.ink,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
            for (final section in edu.sections) ...[
              const SizedBox(height: 14),
              Text(
                section.heading,
                style: TextStyle(
                  color: color,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              for (final point in section.points)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 7, right: 10),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          point,
                          style: const TextStyle(
                            color: SkinTokens.ink,
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 10),
            Text(
              edu.reviewedBy,
              style: const TextStyle(color: SkinTokens.muted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SkinTokens.mint,
                borderRadius: BorderRadius.circular(SkinTokens.radiusSm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Artikel lengkap',
                    style: TextStyle(
                      color: SkinTokens.muted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    edu.articleTitle,
                    style: const TextStyle(
                      color: SkinTokens.ink,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    key: Key('halodoc-link-$findingKey'),
                    onPressed: () => _openArticle(context, edu.url),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Baca di Halodoc'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
