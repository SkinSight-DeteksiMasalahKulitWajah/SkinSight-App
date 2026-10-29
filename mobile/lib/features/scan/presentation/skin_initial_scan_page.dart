import 'dart:typed_data';

import 'package:flutter/material.dart';

import'../data/skin_demo_data.dart';
import'../../history/data/skin_history_repository.dart';
import'../../journeys/data/skin_journey_store.dart';
import'../models/skin_analysis.dart';
import'../../../core/theme/skin_theme.dart';
import'../../../shared/widgets/asset_images.dart';
import'../../../shared/widgets/skin_page_header.dart';
import'../../../shared/widgets/skin_page_background.dart';
import'../../../shared/widgets/design_system/skin_ui.dart';
import'./skin_result_page.dart';
import'./skin_scan_page.dart';

/// Mengumpulkan beberapa foto untuk membentuk satu baseline awal.
/// Nilai rata-rata di sini adalah ringkasan teknis hasil model, bukan skor
/// diagnosis atau tingkat keparahan klinis.
class SkinInitialScanPage extends StatefulWidget {
  const SkinInitialScanPage({
    super.key,
    this.enableCamera = true,
    this.capturePhoto,
    this.autoStartScan = false,
  });

  final bool enableCamera;
  final Future<Uint8List?> Function(int sessionIndex)? capturePhoto;
  final bool autoStartScan;

  @override
  State<SkinInitialScanPage> createState() => _SkinInitialScanPageState();
}

class _SkinInitialScanPageState extends State<SkinInitialScanPage> {
  static const _maxScans = 3;
  final List<SkinAnalysis> _sessions = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoStartScan) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _addScan());
    }
  }

  Future<void> _addScan() async {
    if (_sessions.length >= _maxScans) return;
    final capturePhoto = widget.capturePhoto;
    final bytes = capturePhoto == null
        ? await Navigator.of(context).push<Uint8List>(
            MaterialPageRoute<Uint8List>(
              builder: (_) => SkinScanPage(
                enableCamera: widget.enableCamera,
                returnPhoto: true,
              ),
            ),
          )
        : await capturePhoto(_sessions.length);
    if (!mounted || bytes == null) return;
    final candidate = SkinDemoData.forPhoto(
      bytes,
      sessionIndex: _sessions.length,
    );
    setState(() => _sessions.add(candidate));
    final action = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => SkinResultPage(
          analysis: candidate,
          collectionReview: true,
        ),
      ),
    );
    if (!mounted || action == 'save') return;
    setState(() => _sessions.remove(candidate));
    if (action == 'retry') await _addScan();
  }

  void _removeScan(int index) {
    setState(() {
      _sessions.removeAt(index);
    });
  }

  Future<void> _openScanDetail(SkinAnalysis analysis) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SkinResultPage(
          analysis: analysis,
          archived: true,
        ),
      ),
    );
  }

  SkinAnalysis _averageAnalysis() {
    final countAverages = <String, int>{};
    for (final name in SkinJourneyStore.detectionClasses) {
      final sum = _sessions.fold<int>(
        0,
        (total, session) => total + (session.detectionCounts[name] ?? 0),
      );
      countAverages[name] = (sum / _sessions.length).round();
    }

    final areaAverages = <String, double>{};
    for (final name in SkinJourneyStore.segmentationClasses) {
      final sum = _sessions.fold<double>(
        0,
        (total, session) => total + (session.segmentationAreas[name] ?? 0),
      );
      areaAverages[name] = sum / _sessions.length;
    }

    final confidenceAverages = <String, double>{};
    for (final name in SkinJourneyStore.visualClasses) {
      final values = _sessions
          .map((session) => session.classConfidences[name])
          .whereType<double>()
          .toList();
      if (values.isNotEmpty) {
        confidenceAverages[name] =
            values.reduce((a, b) => a + b) / values.length;
      }
    }

    final typeCounts = <String, int>{};
    for (final session in _sessions) {
      typeCounts.update(session.skinType, (value) => value + 1,
          ifAbsent: () => 1);
    }
    final skinType =
        typeCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    final typeConfidences = _sessions
        .map((session) => session.skinTypeConfidence)
        .whereType<double>()
        .toList();

    final findings = SkinJourneyStore.visualClasses.where((name) {
      if (SkinJourneyStore.detectionClasses.contains(name)) {
        return (countAverages[name] ?? 0) > 0;
      }
      return (areaAverages[name] ?? 0) > 0;
    }).toList();
    final versions = _sessions
        .map((session) => session.modelVersion)
        .whereType<String>()
        .toSet();

    return SkinAnalysis(
      id: 'baseline-${DateTime.now().microsecondsSinceEpoch}',
      analyzedAt: DateTime.now(),
      selfieBytes: _sessions.first.selfieBytes,
      score: 0,
      oil: 0,
      pores: 0,
      acne: 0,
      redness: 0,
      title: 'Baseline dari ${_sessions.length} scan',
      skinType: skinType,
      skinTypeConfidence: typeConfidences.isEmpty
          ? null
          : typeConfidences.reduce((a, b) => a + b) / typeConfidences.length,
      visualFindings: findings,
      modelConnected: _sessions.every((session) => session.modelConnected),
      isDemo: _sessions.any((session) => session.isDemo),
      detectionCounts: countAverages,
      segmentationAreas: areaAverages,
      classConfidences: confidenceAverages,
      modelVersion: versions.length == 1 ? versions.single : 'mixed-baseline',
    );
  }

  Future<String?> _askJourneyName() {
    var name = SkinJourneyStore.instance.selectedJourneyName;
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Beri nama perjalanan'),
        content: TextFormField(
          key: const Key('new-journey-name-field'),
          initialValue: name,
          autofocus: true,
          maxLength: 50,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Nama perjalanan'),
          onChanged: (value) => name = value,
          onFieldSubmitted: (value) {
            if (value.trim().isNotEmpty) Navigator.pop(dialogContext, value);
          },
        ),
        actions: [
          FilledButton(
            key: const Key('confirm-new-journey-name'),
            onPressed: () {
              if (name.trim().isNotEmpty) Navigator.pop(dialogContext, name);
            },
            child: const Text('Simpan perjalanan'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveJourney() async {
    if (_sessions.isEmpty || _saving) return;
    if (SkinJourneyStore.instance.consent != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Izinkan pemrosesan foto pada kuesioner terlebih dahulu.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final average = _averageAnalysis();
    await SkinHistoryRepository.instance.saveLatest(
      average.selfieBytes,
      findings: average.visualFindings,
      skinType: average.skinType,
      modelConnected: average.modelConnected,
      isDemo: average.isDemo,
      detectionCounts: average.detectionCounts,
      segmentationAreas: average.segmentationAreas,
      classConfidences: average.classConfidences,
      skinTypeConfidence: average.skinTypeConfidence,
      modelVersion: average.modelVersion,
      quality: average.isDemo ? 'pass' : 'unchecked',
    );
    if (!mounted) return;
    final name = await _askJourneyName();
    if (!mounted) return;
    if (name == null) {
      setState(() => _saving = false);
      return;
    }
    SkinJourneyStore.instance.finalizeCurrentJourney(name);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final hasScans = _sessions.isNotEmpty;
    final average = hasScans ? _averageAnalysis() : null;
    final full = _sessions.length >= _maxScans;
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
                    title: 'Kumpulan Foto',
                    subtitle: 'Baseline awal Skin Journey',
                    backKey: Key('initial-scan-back'),
                  ),
                  // Kartu progres tetap terlihat agar aksi tambah foto
                  // selalu bisa dijangkau tanpa scroll.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                      decoration: BoxDecoration(
                        gradient: SkinTokens.softGradient,
                        borderRadius:
                            BorderRadius.circular(SkinTokens.radiusXl),
                        border: Border.all(color: Colors.white),
                        boxShadow: SkinTokens.shadows,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Tambah Foto',
                                      style: SkinTokens.section,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${_sessions.length} dari $_maxScans foto tersimpan',
                                      style: SkinTokens.caption,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_sessions.length}/$_maxScans',
                                  style: const TextStyle(
                                    color: SkinTokens.primaryDark,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filled(
                                key: const Key('add-initial-scan'),
                                tooltip:
                                    full ? 'Maksimal 3 foto' : 'Tambah scan',
                                style: IconButton.styleFrom(
                                  backgroundColor: SkinTokens.primary,
                                  minimumSize: const Size(46, 46),
                                ),
                                onPressed: full ? null : _addScan,
                                icon: const Icon(Icons.add_a_photo_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SkinProgressBar(
                            key: const Key('initial-photo-progress'),
                            value: _sessions.length / _maxScans,
                            background: Colors.white,
                            gradient: SkinTokens.brandGradient,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              for (var i = 0; i < _maxScans; i++) ...[
                                Expanded(
                                  child: _PhotoSlot(
                                    number: i + 1,
                                    photo: i < _sessions.length
                                        ? _sessions[i].selfieBytes
                                        : null,
                                    filled: i < _sessions.length,
                                    isNext: i == _sessions.length,
                                    onAdd: _addScan,
                                  ),
                                ),
                                if (i < _maxScans - 1)
                                  const SizedBox(width: 10),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      key: const Key('initial-scan-list'),
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                      children: [
                        if (!hasScans)
                          const _EmptyInitialScan()
                        else
                          for (var index = 0; index < _sessions.length; index++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 11),
                              child: SkinReveal(
                                child: _InitialScanCard(
                                  analysis: _sessions[index],
                                  index: index + 1,
                                  onOpen: () =>
                                      _openScanDetail(_sessions[index]),
                                  onRemove: () => _removeScan(index),
                                ),
                              ),
                            ),
                        if (average != null) ...[
                          const SizedBox(height: 5),
                          _BaselineAverageSummary(
                            analysis: average,
                            photoCount: _sessions.length,
                          ),
                        ],
                      ],
                    ),
                  ),
                  SkinBottomBar(
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const Key('save-initial-scans'),
                        onPressed: !hasScans || _saving ? null : _saveJourney,
                        icon: const Icon(Icons.bookmark_add_outlined),
                        label: Text(
                          _saving ? 'Menyimpan...' : 'Simpan ke Journey',
                        ),
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

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({
    required this.number,
    required this.photo,
    required this.filled,
    required this.isNext,
    required this.onAdd,
  });

  final int number;
  final Uint8List? photo;
  final bool filled;
  final bool isNext;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return AspectRatio(
      aspectRatio: 1.15,
      child: filled
          ? Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: radius,
                  child: photo == null
                      ? const ColoredBox(
                          color: SkinTokens.mint,
                          child: Icon(Icons.face_outlined,
                              color: SkinTokens.primary),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) => Image.memory(
                            photo!,
                            fit: BoxFit.cover,
                            cacheWidth: thumbnailCacheWidth(
                              context,
                              constraints.maxWidth,
                            ),
                          ),
                        ),
                ),
                Positioned(
                  left: 6,
                  top: 6,
                  child: Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      gradient: SkinTokens.brandGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        size: 14, color: Colors.white),
                  ),
                ),
              ],
            )
          : Material(
              color: Colors.white.withValues(alpha: isNext ? .9 : .55),
              borderRadius: radius,
              child: InkWell(
                onTap: isNext ? onAdd : null,
                borderRadius: radius,
                child: CustomPaint(
                  painter: _DashedBorderPainter(
                    color:
                        isNext ? SkinTokens.primary : SkinTokens.borderStrong,
                  ),
                  child: Center(
                    child: Icon(
                      isNext ? Icons.add_rounded : Icons.photo_outlined,
                      color: isNext ? SkinTokens.primary : SkinTokens.subtle,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(1),
        const Radius.circular(17),
      ));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 6), paint);
        distance += 11;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) => old.color != color;
}

class _BaselineAverageSummary extends StatelessWidget {
  const _BaselineAverageSummary({
    required this.analysis,
    required this.photoCount,
  });

  final SkinAnalysis analysis;
  final int photoCount;

  String _metric(String name) {
    if (SkinJourneyStore.detectionClasses.contains(name)) {
      return '${analysis.detectionCounts[name] ?? 0}';
    }
    return '${((analysis.segmentationAreas[name] ?? 0) * 100).toStringAsFixed(0)}%';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('initial-average-result'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SkinTokens.radiusLg),
        border: Border.all(color: SkinTokens.border),
        boxShadow: SkinTokens.shadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkinIconTile(icon: Icons.analytics_outlined, size: 40),
              const SizedBox(width: 11),
              const Expanded(
                child: Text('Rata-rata Hasil', style: SkinTokens.section),
              ),
              SkinPill(label: '$photoCount foto'),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: SkinTokens.mint,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                const Icon(Icons.water_drop_outlined,
                    size: 18, color: SkinTokens.primaryDark),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Jenis kulit',
                    style: TextStyle(color: SkinTokens.muted, fontSize: 12.5),
                  ),
                ),
                Text(
                  analysis.skinType,
                  style: const TextStyle(
                    color: SkinTokens.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (analysis.skinTypeConfidence != null) ...[
                  const SizedBox(width: 7),
                  Text(
                    '${(analysis.skinTypeConfidence! * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: SkinTokens.primaryDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  for (final name in SkinJourneyStore.visualClasses)
                    Container(
                      key: ValueKey('initial-average-$name'),
                      width: itemWidth,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: SkinTokens.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: SkinTokens.muted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            _metric(name),
                            style: const TextStyle(
                              color: SkinTokens.ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyInitialScan extends StatelessWidget {
  const _EmptyInitialScan();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('initial-scan-empty'),
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SkinTokens.radiusLg),
        border: Border.all(color: SkinTokens.border),
      ),
      child: const SkinEmptyState(
        compact: true,
        icon: Icons.add_a_photo_outlined,
        title: 'Belum ada foto baseline',
        message:
            'Ketuk tombol kamera untuk mengambil foto pertama. Foto yang serupa membuat perbandingan lebih akurat.',
      ),
    );
  }
}

class _InitialScanCard extends StatelessWidget {
  const _InitialScanCard({
    required this.analysis,
    required this.index,
    required this.onOpen,
    required this.onRemove,
  });

  final SkinAnalysis analysis;
  final int index;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: ValueKey('initial-scan-$index'),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SkinTokens.radiusLg),
        side: const BorderSide(color: SkinTokens.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('open-initial-scan-$index'),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: analysis.selfieBytes == null
                  ? const ColoredBox(
                      color: SkinTokens.mint,
                      child: SizedBox(
                        width: 66,
                        height: 78,
                        child: Icon(Icons.face_outlined),
                      ),
                    )
                  : Image.memory(
                      analysis.selfieBytes!,
                      width: 66,
                      height: 78,
                      fit: BoxFit.cover,
                      cacheWidth: thumbnailCacheWidth(context, 66),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Foto $index',
                    style: const TextStyle(
                      color: SkinTokens.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${analysis.visualFindings.length} temuan visual · ${analysis.skinType}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: SkinTokens.caption,
                  ),
                  const SizedBox(height: 6),
                  const SkinPill(
                    label: 'Siap dihitung ke baseline',
                    icon: Icons.check_rounded,
                    dense: true,
                  ),
                ],
              ),
            ),
            IconButton(
              key: ValueKey('remove-initial-scan-$index'),
              tooltip: 'Hapus foto $index',
              onPressed: onRemove,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: SkinTokens.coral,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
