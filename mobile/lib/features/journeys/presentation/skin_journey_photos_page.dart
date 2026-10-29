import 'dart:typed_data';
import 'package:flutter/material.dart';
import'../data/skin_journey_store.dart';
import'../../scan/models/skin_analysis.dart';
import'../../../core/theme/skin_theme.dart';
import'../../../shared/widgets/asset_images.dart';
import'../../../shared/widgets/skin_page_header.dart';
import'../../../shared/widgets/skin_page_background.dart';
import'../../../shared/widgets/design_system/skin_ui.dart';
import'../../scan/presentation/skin_result_page.dart';
import'../../scan/presentation/skin_scan_page.dart';

/// Layar kiri sketsa: tambah beberapa sesi, lihat hasil SETIAP foto,
/// dan kembali ke check-in ketika pengguna merasa cukup.
class SkinJourneyPhotosPage extends StatefulWidget {
  const SkinJourneyPhotosPage({super.key});
  @override
  State<SkinJourneyPhotosPage> createState() => _SkinJourneyPhotosPageState();
}

class _SkinJourneyPhotosPageState extends State<SkinJourneyPhotosPage> {
  final store = SkinJourneyStore.instance;

  SkinAnalysis _analysis(JourneyPhoto p) => SkinAnalysis(
        id: p.id,
        analyzedAt: p.date,
        selfieBytes: p.bytes,
        score: 0,
        oil: 0,
        pores: 0,
        acne: 0,
        redness: 0,
        title: 'Hasil sesi foto',
        skinType: p.skinType ?? 'Belum diketahui',
        skinTypeConfidence: p.skinTypeConfidence,
        visualFindings: p.visualFindings,
        modelConnected: p.modelConnected,
        isDemo: p.isDemo,
        detectionCounts: p.detectionCounts,
        segmentationAreas: p.segmentationAreas,
        classConfidences: p.confidences,
        modelVersion: p.modelVersion,
      );

  Future<void> _openResult(JourneyPhoto p) async {
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(
        builder: (_) => SkinResultPage(
            selfieBytes: p.bytes,
            analysis: _analysis(p),
            sessionPreview: true)));
  }

  Future<void> _addPhoto() async {
    if (store.consent != true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Izinkan pemrosesan foto pada kuesioner awal.')));
      return;
    }
    final bytes = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute<Uint8List>(
            builder: (_) => const SkinScanPage(returnPhoto: true)));
    if (!mounted || bytes == null) return;
    // Store menghitung fixture SATU KALI; preview membaca data yang sama.
    store.stagePhoto(bytes);
    final staged = store.pendingPhotos.last;
    await _openResult(staged);
  }

  String _finding(JourneyPhoto photo) {
    final pieces = <String>[];
    for (final name in photo.visualFindings) {
      final count = photo.detectionCounts[name];
      final area = photo.segmentationAreas[name];
      if (count != null) {
        pieces.add('$name $count');
      } else if (area != null) {
        pieces.add('$name ${(area * 100).toStringAsFixed(0)}% mask');
      }
    }
    return pieces.isEmpty ? 'Belum ada hasil' : pieces.join(' · ');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: SkinTokens.background,
        body: SkinPageBackground(
            child: SafeArea(
                bottom: false,
                child: Center(
                    child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: SkinTokens.maxWidth),
                  child: AnimatedBuilder(
                      animation: store,
                      builder: (context, _) => Column(children: [
                            SkinPageHeader(
                              title: 'Sesi Foto',
                              subtitle: store.pendingPhotos.isEmpty
                                  ? 'Belum ada foto di check-in ini'
                                  : '${store.pendingPhotos.length} foto di draft check-in',
                              backKey: const Key('session-back'),
                            ),
                            Expanded(
                                child: ListView(
                                    padding: const EdgeInsets.fromLTRB(
                                        20, 4, 20, 25),
                                    children: [
                                  SkinCard(
                                    gradient: SkinTokens.softGradient,
                                    borderColor: Colors.white,
                                    padding: const EdgeInsets.fromLTRB(
                                        18, 16, 14, 16),
                                    child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          const Expanded(
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                Text('Foto hari ini',
                                                    style: SkinTokens.section),
                                                SizedBox(height: 5),
                                                Text(
                                                    'Pilih foto untuk melihat hasil analisisnya.',
                                                    style: SkinTokens.caption),
                                              ])),
                                          const SizedBox(width: 12),
                                          DecoratedBox(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              boxShadow: SkinTokens.glow(
                                                  SkinTokens.primary,
                                                  opacity: .3),
                                            ),
                                            child: Material(
                                                color: SkinTokens.primary,
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                                child: InkWell(
                                                    key: const Key(
                                                        'add-session'),
                                                    onTap: _addPhoto,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            18),
                                                    child: const Tooltip(
                                                      message: 'Tambah foto',
                                                      child: SizedBox(
                                                          width: 54,
                                                          height: 54,
                                                          child: Icon(
                                                              Icons
                                                                  .add_a_photo_rounded,
                                                              color:
                                                                  Colors.white,
                                                              size: 25)),
                                                    ))),
                                          ),
                                        ]),
                                  ),
                                  const SizedBox(height: 18),
                                  if (store.pendingPhotos.isEmpty)
                                    const SkinCard(
                                      padding: EdgeInsets.all(26),
                                      child: SkinEmptyState(
                                        compact: true,
                                        icon:
                                            Icons.add_photo_alternate_outlined,
                                        title:
                                            'Belum ada foto pada check-in ini',
                                        message:
                                            'Tekan + untuk menambah sesi, atau selesai tanpa foto.',
                                      ),
                                    ),
                                  for (int i = 0;
                                      i < store.pendingPhotos.length;
                                      i++)
                                    Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: SkinReveal(
                                          child: _sessionCard(
                                              store.pendingPhotos[i], i + 1),
                                        )),
                                  if (store.pendingPhotos.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    SkinCard(
                                      color: SkinTokens.mint,
                                      borderColor: null,
                                      shadow: false,
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                'Ringkasan ${store.pendingPhotos.length} sesi',
                                                style: SkinTokens.section),
                                            const SizedBox(height: 10),
                                            // Hasil per foto tidak digabung atau dirata-ratakan;
                                            // pose yang berbeda tidak mewakili area identik.
                                            for (int i = 0;
                                                i < store.pendingPhotos.length;
                                                i++)
                                              Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 6),
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      SkinPill(
                                                        label: 'Sesi ${i + 1}',
                                                        tone: SkinTone.neutral,
                                                        dense: true,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                            _finding(store
                                                                    .pendingPhotos[
                                                                i]),
                                                            style: SkinTokens
                                                                .caption),
                                                      ),
                                                    ],
                                                  )),
                                            const SizedBox(height: 4),
                                            const Text(
                                                'Hasil dicatat per foto, tanpa rata-rata lintas pose.',
                                                style: TextStyle(
                                                    color: SkinTokens.muted,
                                                    fontSize: 11.5)),
                                          ]),
                                    ),
                                  ],
                                ])),
                            SkinBottomBar(
                              child: SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                      key: const Key('finish-sessions'),
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      icon: const Icon(Icons.check_rounded),
                                      label:
                                          const Text('Selesai tambah sesi'))),
                            ),
                          ])),
                )))),
      );

  Widget _sessionCard(JourneyPhoto p, int index) => SkinCard(
        padding: EdgeInsets.zero,
        child: Row(children: [
          Expanded(
            child: InkWell(
                key: Key('open-session-$index'),
                borderRadius: BorderRadius.circular(SkinTokens.radiusLg),
                onTap: () => _openResult(p),
                child: Padding(
                    padding: const EdgeInsets.all(11),
                    child: Row(children: [
                      ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.memory(p.bytes,
                              width: 74,
                              height: 86,
                              fit: BoxFit.cover,
                              cacheWidth: thumbnailCacheWidth(context, 74))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('Sesi $index',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: SkinTokens.ink)),
                            const SizedBox(height: 4),
                            Text(_finding(p),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: SkinTokens.caption),
                            const SizedBox(height: 6),
                            Row(children: [
                              Flexible(
                                child: Text(
                                    '${p.skinType ?? 'Belum diketahui'} · Lihat hasil',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: SkinTokens.primary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12)),
                              ),
                              const Icon(Icons.chevron_right_rounded,
                                  size: 18, color: SkinTokens.primary),
                            ]),
                          ])),
                    ]))),
          ),
          IconButton(
              tooltip: 'Hapus sesi $index',
              onPressed: () => store.clearPendingPhoto(p.id),
              icon: const Icon(Icons.delete_outline_rounded,
                  color: SkinTokens.coral)),
          const SizedBox(width: 5),
        ]),
      );
}
