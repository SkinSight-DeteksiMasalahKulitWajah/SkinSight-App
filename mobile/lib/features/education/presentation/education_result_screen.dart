import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/theme/skin_theme.dart';
import '../../../shared/widgets/design_system/skin_ui.dart';
import '../../../shared/widgets/shimmer_skeleton.dart';
import '../../../shared/widgets/skin_page_background.dart';
import '../../../shared/widgets/skin_page_header.dart';
import '../../history/data/skin_history_repository.dart';
import '../../journeys/data/skin_journey_store.dart';
import '../../scan/models/skin_analysis.dart';
import '../data/recommendation_service.dart';
import '../data/skin_scan_education.dart';

/// Halaman detail hasil edukasi + rekomendasi perawatan LLM.
///
/// Alur navigasi:
/// `SkinScanPage` → `SkinResultPage` → `EducationResultScreen`
///
/// Halaman ini meminta rekomendasi personal dari backend Gemini API,
/// dengan fallback ke edukasi statis jika gagal atau offline.
class EducationResultScreen extends StatefulWidget {
  const EducationResultScreen({
    super.key,
    required this.analysis,
    this.selfieBytes,
  });

  final SkinAnalysis analysis;
  final Uint8List? selfieBytes;

  @override
  State<EducationResultScreen> createState() => _EducationResultScreenState();
}

class _EducationResultScreenState extends State<EducationResultScreen> {
  RecommendationResult? _recommendation;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final cached = widget.analysis.llmRecommendation;
    if (cached != null && cached.isNotEmpty) {
      try {
        _recommendation = RecommendationResult.fromJson(cached);
        _loading = false;
        return;
      } on Object {
        // Cache tidak valid; ambil ulang dari server.
      }
    }
    _fetchRecommendation();
  }

  Future<void> _fetchRecommendation() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final store = SkinJourneyStore.instance;
      final analysis = widget.analysis;

      // Bangun scan data
      final scanData = RecommendationService.scanDataFromAnalysis(
        skinType: analysis.skinType,
        skinTypeConfidence: analysis.skinTypeConfidence,
        visualFindings: analysis.visualFindings,
        detectionCounts: analysis.detectionCounts,
        segmentationAreas: analysis.segmentationAreas,
        classConfidences: analysis.classConfidences,
      );

      // Bangun checkin history dari journey
      final checkinHistory = store.checkins
          .map((c) => <String, dynamic>{
                'week': store.checkins.indexOf(c) + 1,
                'per_class': c.perClass,
                'treatment': c.treatment,
                'irritation': c.irritation,
              })
          .toList();

      final result = await RecommendationService.instance.getRecommendation(
        scanData: scanData,
        quizAnswers: store.answers,
        checkinHistory: checkinHistory,
      );

      // Simpan hasil rekomendasi LLM ke riwayat scan Supabase agar tetap ada
      // setelah user keluar lalu masuk kembali.
      unawaited(
        SkinHistoryRepository.instance.updateRecommendation(
          analysis.id,
          result.toJson(),
        ),
      );

      if (!mounted) return;
      setState(() {
        _recommendation = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  String _pct(double value) => '${(value * 100).toStringAsFixed(0)}%';

  String _amount(String name) => SkinJourneyStore.detectionClasses
          .contains(name)
      ? '${widget.analysis.detectionCounts[name] ?? 0} titik'
      : '${((widget.analysis.segmentationAreas[name] ?? 0) * 100).toStringAsFixed(0)}%';

  @override
  Widget build(BuildContext context) {
    final photo = widget.analysis.selfieBytes ?? widget.selfieBytes;
    final store = SkinJourneyStore.instance;
    final needsCare =
        store.answers['M03'] == 'Sedang-berat' || store.answers['M06'] == 'Ya';

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
                  return Column(
                    children: [
                      SkinPageHeader(
                        title: 'Rekomendasi Perawatan',
                        subtitle:
                            'Panduan personal AI berdasarkan scan & profil',
                        backKey: const Key('education-result-back'),
                        trailing: SkinCircleButton(
                          key: const Key('education-result-refresh'),
                          tooltip: 'Muat ulang rekomendasi AI',
                          icon: Icons.refresh_rounded,
                          iconColor: SkinTokens.primary,
                          onPressed: _loading ? null : _fetchRecommendation,
                        ),
                      ),
                      Expanded(
                        child: _loading
                            ? _buildLoading()
                            : _recommendation != null
                                ? _buildLLMResult(
                                    photo, _recommendation!, needsCare)
                                : _buildFallback(photo, needsCare),
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

  // ─── Loading State ───────────────────────────────────────────────

  Widget _buildLoading() => ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: const [
          ShimmerLoading(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SkeletonBox(
                  height: 112,
                  borderRadius: BorderRadius.all(Radius.circular(22)),
                ),
                SizedBox(height: 16),
                SkeletonBox(
                  height: 156,
                  borderRadius: BorderRadius.all(Radius.circular(22)),
                ),
                SizedBox(height: 16),
                SkeletonBox(
                  height: 196,
                  borderRadius: BorderRadius.all(Radius.circular(22)),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Menyusun rekomendasi perawatan personal...',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SkinTokens.muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );

  // ─── LLM Result ──────────────────────────────────────────────────

  Widget _buildLLMResult(
      Uint8List? photo, RecommendationResult rec, bool needsCare) {
    return ListView(
      key: const Key('education-result-list'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        // Ringkasan sesi
        _SummaryCard(
          analysis: widget.analysis,
          photo: photo,
          pct: _pct,
          amount: _amount,
        ),

        const SizedBox(height: 20),

        // ─ Ringkasan AI (Deep Botanical Canopy) ─
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: SkinTokens.deepGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: SkinTokens.glow(SkinTokens.hero, opacity: .2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.auto_awesome,
                      size: 18, color: Color(0xFFD4E8E0)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Ringkasan AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        )),
                  ),
                ]),
                const SizedBox(height: 10),
                Text(
                  rec.summary,
                  style: const TextStyle(
                    color: Color(0xFFEAF4F0),
                    fontSize: 14,
                    height: 1.55,
                  ),
                ),
                if (rec.skinTypeNote.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.water_drop_outlined,
                            size: 16, color: Color(0xFFD4E8E0)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(rec.skinTypeNote,
                              style: const TextStyle(
                                color: Color(0xFFEAF4F0),
                                fontSize: 13,
                                height: 1.4,
                              )),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // ─ Medical Warning ─
        if (rec.medicalWarning != null) ...[
          const SizedBox(height: 14),
          SkinNotice(
            tone: SkinTone.danger,
            icon: Icons.local_hospital_outlined,
            message: rec.medicalWarning!,
          ),
        ],

        // ─ Edukasi per temuan ─
        if (rec.findingsEducation.isNotEmpty) ...[
          const SizedBox(height: 24),
          const SkinSectionTitle(
            title: 'Analisis per temuan',
            subtitle: 'Penjelasan dan langkah perawatan spesifik dari AI.',
          ),
          const SizedBox(height: 12),
          for (final edu in rec.findingsEducation) ...[
            _LLMFindingCard(education: edu),
            const SizedBox(height: 10),
          ],
        ],

        // ─ Rutinitas Harian ─
        if (rec.routine.isNotEmpty) ...[
          const SizedBox(height: 24),
          const SkinSectionTitle(
            title: 'Rutinitas harian',
            subtitle: 'Langkah perawatan yang disarankan oleh AI.',
          ),
          const SizedBox(height: 12),
          SkinCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                for (int i = 0; i < rec.routine.length; i++) ...[
                  if (i > 0)
                    Divider(
                        height: 1, color: Colors.white.withValues(alpha: .9)),
                  _RoutineRow(step: rec.routine[i]),
                ],
              ],
            ),
          ),
        ],

        // ─ Bahan Aktif ─
        if (rec.recommendedIngredients.isNotEmpty ||
            rec.avoidIngredients.isNotEmpty) ...[
          const SizedBox(height: 24),
          const SkinSectionTitle(
            title: 'Panduan bahan aktif',
            subtitle: 'Rekomendasi berdasarkan profil kulitmu.',
          ),
          const SizedBox(height: 12),
          if (rec.recommendedIngredients.isNotEmpty)
            _IngredientCard(
              icon: Icons.check_circle_outline,
              color: SkinTokens.primary,
              title: 'Disarankan',
              items: rec.recommendedIngredients,
            ),
          if (rec.avoidIngredients.isNotEmpty) ...[
            const SizedBox(height: 10),
            _IngredientCard(
              icon: Icons.block_outlined,
              color: const Color(0xFFB8646B),
              title: 'Hindari',
              items: rec.avoidIngredients,
            ),
          ],
        ],

        // ─ Tips Gaya Hidup ─
        if (rec.lifestyleTips.isNotEmpty) ...[
          const SizedBox(height: 24),
          const SkinSectionTitle(
            title: 'Tips gaya hidup',
            subtitle: 'Kebiasaan sehari-hari yang mendukung kesehatan kulit.',
          ),
          const SizedBox(height: 12),
          SkinCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < rec.lifestyleTips.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: SkinTokens.mint,
                          shape: BoxShape.circle,
                        ),
                        child: Text('${i + 1}',
                            style: const TextStyle(
                              color: SkinTokens.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            )),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(rec.lifestyleTips[i],
                            style: const TextStyle(
                              color: SkinTokens.ink,
                              fontSize: 13.5,
                              height: 1.4,
                            )),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],

        // ─ Disclaimer ─
        const SizedBox(height: 14),
        SkinNotice(
          dense: true,
          tone: SkinTone.neutral,
          message: rec.disclaimer,
        ),
      ],
    );
  }

  // ─── Fallback (statis, sama seperti sebelumnya + error banner) ───

  Widget _buildFallback(Uint8List? photo, bool needsCare) {
    final educated = widget.analysis.visualFindings
        .where(scanEducation.containsKey)
        .toList(growable: false);

    return ListView(
      key: const Key('education-result-list'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: SkinCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.cloud_off_outlined,
                        size: 18, color: SkinTokens.muted),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Rekomendasi AI tidak tersedia',
                        style: TextStyle(
                          color: SkinTokens.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  const Text(
                    'Menampilkan panduan edukasi standar. Coba lagi untuk mendapatkan rekomendasi personal.',
                    style: TextStyle(
                      color: SkinTokens.muted,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _fetchRecommendation,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Coba lagi'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        _SummaryCard(
          analysis: widget.analysis,
          photo: photo,
          pct: _pct,
          amount: _amount,
        ),
        const SizedBox(height: 24),
        const SkinSectionTitle(
          title: 'Edukasi perawatan',
          subtitle: 'Panduan umum, bukan resep atau kepastian hasil.',
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
            _StaticEducationCard(
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
          message: 'Hasil visual bukan diagnosis atau persentase kesembuhan.',
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Widget Helpers
// ═══════════════════════════════════════════════════════════════════

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
class _LLMFindingCard extends StatelessWidget {
  const _LLMFindingCard({required this.education});
  final FindingEducation education;

  @override
  Widget build(BuildContext context) {
    final color = findingColor(education.finding);
    final icon = findingIcon(education.finding);

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
                education.findingLabel.isNotEmpty
                    ? education.findingLabel
                    : education.finding,
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
            education.explanation,
            style: const TextStyle(
              color: SkinTokens.ink,
              fontSize: 13.5,
              height: 1.55,
            ),
          ),
          if (education.careTips.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Langkah perawatan:',
                style: TextStyle(
                  color: SkinTokens.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                )),
            const SizedBox(height: 6),
            for (final tip in education.careTips)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(tip,
                          style: const TextStyle(
                            color: SkinTokens.ink,
                            fontSize: 13,
                            height: 1.45,
                          )),
                    ),
                  ],
                ),
              ),
          ],
          if (education.timeline.isNotEmpty) ...[
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
                    child: Text(education.timeline,
                        style: const TextStyle(
                          color: SkinTokens.muted,
                          fontSize: 12,
                          height: 1.4,
                        )),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Baris rutinitas perawatan.
class _RoutineRow extends StatelessWidget {
  const _RoutineRow({required this.step});
  final RoutineStep step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: SkinTokens.brandGradient,
              shape: BoxShape.circle,
            ),
            child: Text('${step.order}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                )),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(step.stepName,
                        style: const TextStyle(
                          color: SkinTokens.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        )),
                  ),
                  SkinPill(
                    label: step.when,
                    tone: SkinTone.info,
                    dense: true,
                  ),
                ]),
                const SizedBox(height: 4),
                Text(step.description,
                    style: const TextStyle(
                      color: SkinTokens.ink,
                      fontSize: 13,
                      height: 1.45,
                    )),
                if (step.ingredientHighlights.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final ing in step.ingredientHighlights)
                        SkinPill(
                          label: ing,
                          tone: SkinTone.neutral,
                          dense: true,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu bahan aktif (disarankan / hindari).
class _IngredientCard extends StatelessWidget {
  const _IngredientCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.items,
  });

  final IconData icon;
  final Color color;
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return SkinCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                )),
          ]),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final item in items)
                SkinPill(
                  label: item,
                  tone: color == SkinTokens.primary
                      ? SkinTone.primary
                      : SkinTone.neutral,
                  dense: true,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Kartu edukasi statis (fallback, identik dengan versi lama).
class _StaticEducationCard extends StatelessWidget {
  const _StaticEducationCard({
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
