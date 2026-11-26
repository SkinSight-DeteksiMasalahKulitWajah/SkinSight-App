import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/theme/skin_theme.dart';
import '../../../shared/widgets/design_system/skin_ui.dart';
import '../../../shared/widgets/skin_page_background.dart';
import '../../../shared/widgets/skin_page_header.dart';
import '../../journeys/data/skin_journey_store.dart';
import '../../scan/models/skin_analysis.dart';
import '../data/skin_scan_education.dart';
import 'widgets/halodoc_education_section.dart';

/// Halaman edukasi perawatan untuk hasil scan.
///
/// Alur navigasi:
/// `SkinScanPage` → `SkinResultPage` → `EducationResultScreen`
///
/// Isinya ringkasan sesi dan edukasi per temuan bersumber dari Halodoc
/// (statis, tanpa AI), sehingga tampil seketika dan tetap jalan saat offline.
class EducationResultScreen extends StatelessWidget {
  const EducationResultScreen({
    super.key,
    required this.analysis,
    this.selfieBytes,
  });

  final SkinAnalysis analysis;
  final Uint8List? selfieBytes;

  String _pct(double value) => '${(value * 100).toStringAsFixed(0)}%';

  String _amount(String name) => SkinJourneyStore.detectionClasses
          .contains(name)
      ? '${analysis.detectionCounts[name] ?? 0} titik'
      : '${((analysis.segmentationAreas[name] ?? 0) * 100).toStringAsFixed(0)}%';

  @override
  Widget build(BuildContext context) {
    final photo = analysis.selfieBytes ?? selfieBytes;

    return Scaffold(
      backgroundColor: SkinTokens.background,
      body: SkinPageBackground(
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: SkinTokens.maxWidth),
              child: Column(
                children: [
                  const SkinPageHeader(
                    title: 'Edukasi Perawatan',
                    subtitle: 'Panduan dari Halodoc sesuai hasil scanmu',
                    backKey: Key('education-result-back'),
                  ),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: SkinJourneyStore.instance,
                      builder: (context, _) {
                        final answers = SkinJourneyStore.instance.answers;
                        final needsCare = answers['M03'] == 'Sedang-berat' ||
                            answers['M06'] == 'Ya';
                        return ListView(
                          key: const Key('education-result-list'),
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          children: [
                            _SummaryCard(
                              analysis: analysis,
                              photo: photo,
                              pct: _pct,
                              amount: _amount,
                            ),
                            const SizedBox(height: 24),
                            HalodocEducationSection(
                                findings: analysis.visualFindings),
                            if (needsCare) ...[
                              const SizedBox(height: 4),
                              const SkinNotice(
                                tone: SkinTone.danger,
                                icon: Icons.local_hospital_outlined,
                                message:
                                    'Jika sedang dalam perawatan dokter atau mengalami keluhan berat, utamakan arahan tenaga kesehatan.',
                              ),
                            ],
                            const SizedBox(height: 14),
                            const SkinNotice(
                              dense: true,
                              tone: SkinTone.neutral,
                              message:
                                  'Hasil visual bukan diagnosis atau persentase kesembuhan.',
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  SkinBottomBar(
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const Key('education-result-done'),
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('Kembali ke hasil analisis'),
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

/// Ringkasan sesi (sama seperti sebelumnya).
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.analysis,
    required this.photo,
    required this.pct,
    required this.amount,
  });

  final SkinAnalysis analysis;
  final Uint8List? photo;
  final String Function(double) pct;
  final String Function(String) amount;

  @override
  Widget build(BuildContext context) {
    final findings = analysis.visualFindings;
    final type = skinTypeLabels[analysis.skinType] ?? analysis.skinType;
    return SkinCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: photo != null
                    ? Image.memory(photo!,
                        width: 64, height: 76, fit: BoxFit.cover)
                    : const ColoredBox(
                        color: SkinTokens.mint,
                        child: SizedBox(
                          width: 64,
                          height: 76,
                          child: Icon(Icons.face_outlined),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('HASIL SESI INI', style: SkinTokens.eyebrow),
                    const SizedBox(height: 3),
                    Text(type, style: SkinTokens.number.copyWith(fontSize: 22)),
                    const SizedBox(height: 3),
                    Text(
                      [
                        SkinFormat.longDate(analysis.analyzedAt),
                        if (analysis.skinTypeConfidence != null)
                          'Confidence ${pct(analysis.skinTypeConfidence!)}',
                      ].join(' · '),
                      style: SkinTokens.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (findings.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final name in findings)
                  SkinPill(
                    label: '${findingLabels[name] ?? name} · ${amount(name)}',
                    tone: SkinTone.neutral,
                    dense: true,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Kartu edukasi LLM untuk satu temuan.
