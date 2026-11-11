import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../data/skin_demo_data.dart';
import '../../education/data/skin_scan_education.dart';
import '../../education/presentation/education_result_screen.dart';
import '../../history/data/skin_history_repository.dart';
import '../../journeys/data/skin_journey_store.dart';
import '../models/skin_analysis.dart';
import '../../../core/theme/skin_theme.dart';
import './widgets/skin_analysis_view.dart';
import '../../../shared/widgets/skin_page_background.dart';
import '../../../shared/widgets/design_system/skin_ui.dart';
import '../../progress/presentation/skin_progress_page.dart';
import './skin_scan_page.dart';

/// Hasil satu foto. Dalam prototipe hasil berasal dari fixture demo yang
/// SAMA dengan catatan Skin Journey setelah pengguna menekan Simpan.
class SkinResultPage extends StatefulWidget {
  final Uint8List? selfieBytes;
  final SkinAnalysis? analysis;
  final bool archived;

  /// Hasil foto sementara sebelum dimasukkan ke pengumpulan scan pertama.
  final bool collectionReview;

  /// Dipakai untuk sesi foto di dalam check-in; tidak menyimpan baseline baru.
  final bool sessionPreview;
  const SkinResultPage(
      {super.key,
      this.selfieBytes,
      this.analysis,
      this.archived = false,
      this.collectionReview = false,
      this.sessionPreview = false});
  @override
  State<SkinResultPage> createState() => _SkinResultPageState();
}

class _SkinResultPageState extends State<SkinResultPage> {
  late final SkinAnalysis? _data;
  bool _saving = false;
  bool _saved = false;
  final _findingsKey = GlobalKey();

  final Map<String, String> _typeLabels = {
    'acne': 'Jerawat',
    'oily': 'Berminyak',
    'dry': 'Kering',
    'normal': 'Normal',
  };

  @override
  void initState() {
    super.initState();
    _data = widget.analysis ??
        (widget.selfieBytes == null
            ? null
            : SkinDemoData.forPhoto(widget.selfieBytes!));
  }

  String _pct(double v) => '${(v * 100).toStringAsFixed(0)}%';

  void _scrollTo(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: SkinTokens.slow,
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _save() async {
    final a = _data;
    final bytes = a?.selfieBytes ?? widget.selfieBytes;
    if (_saved || _saving || bytes == null || a == null) return;
    if (SkinJourneyStore.instance.consent != true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Izinkan pemrosesan foto di kuesioner terlebih dahulu.')));
      return;
    }
    setState(() => _saving = true);
    await SkinHistoryRepository.instance.saveLatest(
      bytes,
      findings: a.visualFindings,
      skinType: a.skinType,
      modelConnected: a.modelConnected,
      isDemo: a.isDemo,
      detectionCounts: a.detectionCounts,
      segmentationAreas: a.segmentationAreas,
      classConfidences: a.classConfidences,
      skinTypeConfidence: a.skinTypeConfidence,
      modelVersion: a.modelVersion,
      quality: a.isDemo ? 'pass' : 'unchecked',
    );
    if (!mounted) return;
    setState(() {
      _saved = true;
      _saving = false;
    });
    Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const SkinProgressPage()));
  }

  List<SkinMetric> _metrics(List<String> found, SkinAnalysis a) => [
        for (final c in found.take(4))
          (
            label: findingLabels[c] ?? c,
            value: _amount(c, a),
            fraction: a.classConfidences[c] ??
                (a.segmentationAreas[c] ?? .3).clamp(0.0, 1.0),
          ),
      ];

  String _amount(String name, SkinAnalysis a) =>
      SkinJourneyStore.detectionClasses.contains(name)
          ? '${a.detectionCounts[name] ?? 0} titik'
          : '${((a.segmentationAreas[name] ?? 0) * 100).toStringAsFixed(0)}%';

  /// Navigasi ke halaman DETAIL edukasi (bukan halaman/dialog yang sama)
  /// dengan membawa data hasil scan yang sedang dibuka.
  Future<void> _openEducation(SkinAnalysis analysis) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => EducationResultScreen(
          analysis: analysis,
          selfieBytes: widget.selfieBytes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = _data;
    final photo = a?.selfieBytes ?? widget.selfieBytes;
    final hasData = a != null && (a.modelConnected || a.isDemo);
    final found = a == null || !hasData ? const <String>[] : a.visualFindings;
    final skinTypeConfidence = a?.skinTypeConfidence;
    final other = SkinJourneyStore.visualClasses
        .where((c) => !found.contains(c))
        .toList();
    final type = hasData ? a.skinType : 'Belum diketahui';
    final typeDesc = switch (type) {
      'Dry' =>
        'Cenderung membutuhkan perhatian pada kelembapan dan toleransi bahan aktif.',
      'Oily' =>
        'Formulasi ringan dapat membantu kenyamanan, tanpa mengabaikan pelembap.',
      'Normal' => 'Fokuskan perawatan pada keluhan dan respons kulit.',
      'Combination' =>
        'Area T-zone dan pipi bisa memiliki kebutuhan yang berbeda.',
      _ => 'Estimasi jenis kulit belum tersedia.',
    };
    final educated = found.where(scanEducation.containsKey).toList();

    return Scaffold(
      backgroundColor: SkinTokens.backgroundLight,
      body: SkinPageBackground(
          child: SafeArea(
              bottom: false,
              child: Center(
                  child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: SkinTokens.maxWidth),
                // Seluruh isi dibangun sekaligus agar Scrollable.ensureVisible
                // ke seksi temuan selalu menemukan targetnya.
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SkinReveal(
                        child: SkinAnalysisView(
                          photo: photo == null ? null : MemoryImage(photo),
                          photoHeight: 400,
                          badge: hasData
                              ? 'Jenis kulit: ${skinTypeLabels[type] ?? type}'
                              : 'Belum ada hasil',
                          backKey: const Key('result-back'),
                          onBack: () => Navigator.of(context).maybePop(),
                          trailing: a != null && a.isDemo
                              ? const SkinPill(
                                  label: 'Demo',
                                  tone: SkinTone.warning,
                                  icon: Icons.science_outlined,
                                )
                              : null,
                          metrics: hasData ? _metrics(found, a) : const [],
                          emptyMessage: hasData
                              ? 'Tidak ada temuan visual pada sesi ini.'
                              : 'Hasil analisis belum tersedia.',
                          recommendationLabel: educated.isNotEmpty
                              ? 'Rekomendasi perawatan'
                              : 'Lihat rincian temuan',
                          // Edukasi dibuka sebagai halaman terpisah, bukan
                          // digulir pada halaman hasil yang sama.
                          onRecommendation: educated.isNotEmpty && a != null
                              ? () => _openEducation(a)
                              : () => _scrollTo(_findingsKey),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SkinTokens.pageInset - 4,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              widget.sessionPreview
                                  ? 'Hasil Sesi Foto'
                                  : 'Hasil Analisis',
                              style: SkinTokens.title,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [
                                if (a != null)
                                  SkinFormat.longDate(a.analyzedAt),
                                hasData
                                    ? '${found.length} jenis temuan visual'
                                    : 'Hasil analisis belum tersedia',
                              ].join(' · '),
                              style: SkinTokens.caption,
                            ),
                            const SizedBox(height: 16),
                            SkinReveal(
                              delay: const Duration(milliseconds: 80),
                              child: _SkinTypeCard(
                                type: _typeLabels[type] ?? type,
                                description: typeDesc,
                                confidence: hasData ? skinTypeConfidence : null,
                                pct: _pct,
                              ),
                            ),
                            const SizedBox(height: 26),
                            SkinSectionTitle(
                              key: _findingsKey,
                              title: 'Temuan visual',
                              subtitle:
                                  'Ringkasan temuan per kelas · jumlah deteksi, luas mask, dan confidence.',
                            ),
                            const SizedBox(height: 12),
                            if (hasData)
                              SkinReveal(
                                delay: const Duration(milliseconds: 140),
                                child: SkinCard(
                                  key: const Key('result-compact-findings-v10'),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  child: Column(children: [
                                    for (final c in found) ...[
                                      if (c != found.first)
                                        Divider(
                                          height: 1,
                                          color: Colors.white
                                              .withValues(alpha: .9),
                                        ),
                                      _findingRow(c, a),
                                    ],
                                  ]),
                                ),
                              )
                            else
                              const SkinCard(
                                child: SkinEmptyState(
                                  compact: true,
                                  icon: Icons.image_search_rounded,
                                  title: 'Belum ada hasil',
                                  message: 'Belum ada hasil yang tersimpan.',
                                ),
                              ),
                            if (other.isNotEmpty && hasData) ...[
                              const SizedBox(height: 14),
                              const Row(children: [
                                Icon(Icons.remove_circle_outline,
                                    color: SkinTokens.muted, size: 16),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text('Tidak terdeteksi pada sesi ini',
                                      style: TextStyle(
                                        color: SkinTokens.muted,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                      )),
                                ),
                              ]),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  for (final c in other)
                                    SkinPill(
                                      label: findingLabels[c] ?? c,
                                      tone: SkinTone.neutral,
                                    ),
                                ],
                              ),
                            ],
                            // Hasil edukasi TIDAK lagi ditampilkan di halaman
                            // ini. Kartu ringkas berikut hanya menjadi pintu
                            // masuk ke halaman detail edukasi terpisah.
                            if (educated.isNotEmpty) ...[
                              const SizedBox(height: 28),
                              const SkinSectionTitle(
                                title: 'Edukasi perawatan',
                                subtitle:
                                    'Panduan umum untuk temuan pada sesi ini.',
                              ),
                              const SizedBox(height: 12),
                              SkinCard(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      const SkinIconTile(
                                        icon: Icons.menu_book_rounded,
                                        size: 44,
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          'Pahami setiap temuan dengan panduan singkat perawatan dan waktu evaluasinya.',
                                          style: SkinTokens.caption,
                                        ),
                                      ),
                                    ]),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        for (final c in educated)
                                          SkinPill(
                                            label: findingLabels[c] ?? c,
                                            tone: SkinTone.primary,
                                            dense: true,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton.icon(
                                        key: const Key('open-education-result'),
                                        onPressed: a == null
                                            ? null
                                            : () => _openEducation(a),
                                        icon: const Icon(
                                            Icons.auto_stories_outlined),
                                        label: const Text(
                                            'Lihat Edukasi Perawatan'),
                                      ),
                                    ),
                                  ],
                                ),
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
                        ),
                      ),
                    ],
                  ),
                ),
              )))),
      bottomNavigationBar: widget.archived
          ? null
          : widget.collectionReview
              ? SkinBottomBar(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          key: const Key('review-retry-scan'),
                          onPressed: () => Navigator.of(context).pop('retry'),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Ulangi'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: FilledButton.icon(
                          key: const Key('review-save-photo'),
                          onPressed: () => Navigator.of(context).pop('save'),
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: const Text('Simpan Foto'),
                        ),
                      ),
                    ],
                  ),
                )
              : widget.sessionPreview
                  ? SkinBottomBar(
                      child: SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                              key: const Key('session-preview-done'),
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Sesi masuk draft • Kembali'))))
                  : SkinBottomBar(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.of(context)
                                  .pushReplacement(MaterialPageRoute<void>(
                                builder: (_) => const SkinScanPage(),
                              )),
                              icon: const Icon(Icons.refresh_rounded, size: 20),
                              label: const Text('Ulangi'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 3,
                            child: FilledButton.icon(
                              key: const Key('save-result'),
                              onPressed: _saving || _saved ? null : _save,
                              icon: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.bookmark_add_outlined,
                                      size: 20,
                                    ),
                              label: Text(
                                _saving ? 'Menyimpan...' : 'Simpan ke Journey',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  IconData _findingIcon(String type) {
    switch (type.toLowerCase()) {
      case 'acne':
        return Icons.warning_amber_rounded;
      case 'oily':
        return Icons.water_drop;
      case 'dry':
        return Icons.dry; // Sesuaikan jika ada icon lain
      default:
        return Icons.check_circle_outline;
    }
  }

  // Satu panel ringkas; setiap kelas satu BARIS, bukan kartu tinggi 156 px.
  Widget _findingRow(String name, SkinAnalysis a) {
    final detection = SkinJourneyStore.detectionClasses.contains(name);
    final amount = detection
        ? '${a.detectionCounts[name] ?? 0}'
        : '${((a.segmentationAreas[name] ?? 0) * 100).toStringAsFixed(0)}%';
    final confidence = a.classConfidences[name];
    final color = findingColor(name);
    return Padding(
      key: ValueKey('result-finding-$name'),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white)),
            child: Icon(_findingIcon(name), color: color, size: 20)),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style: const TextStyle(
                    color: SkinTokens.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5)),
            if (confidence != null) ...[
              const SizedBox(height: 7),
              SkinProgressBar(
                value: confidence,
                height: 5,
                color: color,
                background: color.withValues(alpha: .12),
              ),
              const SizedBox(height: 4),
              Text('Keyakinan AI ${_pct(confidence)}',
                  style:
                      const TextStyle(color: SkinTokens.muted, fontSize: 11)),
            ],
          ],
        )),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(amount,
              style: const TextStyle(
                  fontSize: 22,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: SkinTokens.ink)),
          Text(detection ? 'temuan' : 'luas mask',
              style: const TextStyle(
                  color: SkinTokens.muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }
}

class _SkinTypeCard extends StatelessWidget {
  const _SkinTypeCard({
    required this.type,
    required this.description,
    required this.confidence,
    required this.pct,
  });

  final String type;
  final String description;
  final double? confidence;
  final String Function(double) pct;

  @override
  Widget build(BuildContext context) {
    return SkinCard(
      padding: const EdgeInsets.all(18),
      radius: 30,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            const SkinIconTile(icon: Icons.water_drop_outlined, size: 50),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ESTIMASI JENIS KULIT', style: SkinTokens.eyebrow),
                  const SizedBox(height: 4),
                  Text(type, style: SkinTokens.number.copyWith(fontSize: 24)),
                ],
              ),
            ),
            if (confidence != null) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                decoration: BoxDecoration(
                  color: SkinTokens.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      pct(confidence!),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'Confidence',
                      style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ]),
          const SizedBox(height: 12),
          Text(description, style: SkinTokens.caption),
        ],
      ),
    );
  }
}

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
