import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/theme/skin_theme.dart';
import '../../../shared/widgets/design_system/skin_ui.dart';
import '../../../shared/widgets/skin_page_background.dart';
import '../../../shared/widgets/skin_page_header.dart';
import '../../journeys/data/skin_journey_store.dart';
import '../../scan/models/skin_analysis.dart';
import '../data/skin_scan_education.dart';

/// Halaman khusus detail hasil edukasi setelah pengguna mengambil/mengunggah
/// foto. Sebelumnya konten edukasi menempel di halaman hasil analisis;
/// sekarang dipisah agar hasil deteksi dan edukasi tidak lagi ditampilkan
/// pada satu halaman yang sama maupun lewat dialog/popup.
///
/// Alur navigasi:
/// `SkinScanPage` → `SkinResultPage` → `EducationResultScreen`
/// dengan membawa [analysis] (data hasil scan) dari halaman sebelumnya.
class EducationResultScreen extends StatelessWidget {
  const EducationResultScreen({
    super.key,
    required this.analysis,
    this.selfieBytes,
  });

  /// Data hasil scan yang dibawa dari halaman scan/hasil analisis.
  final SkinAnalysis analysis;

  /// Foto cadangan bila [analysis.selfieBytes] tidak tersedia.
  final Uint8List? selfieBytes;

  String _pct(double value) => '${(value * 100).toStringAsFixed(0)}%';

  String _amount(String name) =>
      SkinJourneyStore.detectionClasses.contains(name)
          ? '${analysis.detectionCounts[name] ?? 0} titik'
          : '${((analysis.segmentationAreas[name] ?? 0) * 100).toStringAsFixed(0)}%';

  @override
  Widget build(BuildContext context) {
    final photo = analysis.selfieBytes ?? selfieBytes;
    final educated = analysis.visualFindings
        .where(scanEducation.containsKey)
        .toList(growable: false);

    // Pola pembacaan state projek (provider/ChangeNotifier): UI mendengarkan
    // SkinJourneyStore lewat AnimatedBuilder, sama seperti halaman lain.
    return Scaffold(
      backgroundColor: SkinTokens.background,
      body: SkinPageBackground(
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: SkinTokens.maxWidth),
              child: AnimatedBuilder(
                animation: SkinJourneyStore.instance,
                builder: (context, _) {
                  final store = SkinJourneyStore.instance;
                  final needsCare = store.answers['M03'] == 'Sedang-berat' ||
                      store.answers['M06'] == 'Ya';
                  return Column(
                    children: [
                      const SkinPageHeader(
                        title: 'Hasil Edukasi',
                        subtitle: 'Panduan perawatan untuk temuan sesi ini',
                        backKey: Key('education-result-back'),
                      ),
                      Expanded(
                        child: ListView(
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
                            const SkinSectionTitle(
                              title: 'Edukasi perawatan',
                              subtitle:
                                  'Panduan umum, bukan resep atau kepastian hasil.',
                            ),
                            const SizedBox(height: 12),
                            if (educated.isEmpty)
                              const SkinCard(
                                child: SkinEmptyState(
                                  compact: true,
                                  icon: Icons.menu_book_outlined,
                                  title: 'Belum ada panduan khusus',
                                  message:
                                      'Temuan pada sesi ini belum memiliki materi edukasi khusus.',
                                ),
                              )
                            else
                              for (final name in educated) ...[
                                _EducationCard(
                                  name: findingLabels[name] ?? name,
                                  color: findingColor(name),
                                  icon: findingIcon(name),
                                  body: scanEducation[name]!.$1,
                                  note: scanEducation[name]!.$2,
                                ),
                                const SizedBox(height: 10),
                              ],
                            if (needsCare)
                              const SkinNotice(
                                tone: SkinTone.danger,
                                icon: Icons.local_hospital_outlined,
                                message:
                                    'Jika sedang dalam perawatan dokter atau mengalami keluhan berat, utamakan arahan tenaga kesehatan.',
                              ),
                            const SizedBox(height: 14),
                            const SkinNotice(
                              dense: true,
                              tone: SkinTone.neutral,
                              message:
                                  'Hasil visual bukan diagnosis atau persentase kesembuhan.',
                            ),
                          ],
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
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ringkasan singkat sesi: foto, jenis kulit, tanggal, dan daftar temuan.
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
                    ? Image.memory(
                        photo!,
                        width: 64,
                        height: 76,
                        fit: BoxFit.cover,
                      )
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
                    Text(
                      type,
                      style: SkinTokens.number.copyWith(fontSize: 22),
                    ),
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
                    label:
                        '${findingLabels[name] ?? name} · ${amount(name)}',
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

/// Satu kartu panduan edukasi untuk satu temuan.
class _EducationCard extends StatelessWidget {
  const _EducationCard({
    required this.name,
    required this.color,
    required this.icon,
    required this.body,
    required this.note,
  });

  final String name;
  final Color color;
  final IconData icon;
  final String body;
  final String note;

  @override
  Widget build(BuildContext context) {
    return SkinCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: SkinTokens.ink,
                  fontSize: 15,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              color: SkinTokens.ink,
              fontSize: 13.5,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(Icons.schedule_rounded,
                      size: 14, color: SkinTokens.muted),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    note,
                    style: const TextStyle(
                      color: SkinTokens.muted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
