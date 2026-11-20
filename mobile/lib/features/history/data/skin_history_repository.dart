import 'dart:async';
import 'dart:ui' show Rect;
import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/cloud_storage.dart';
import '../../../core/api/cloud_sync.dart';
import '../../scan/models/skin_analysis.dart';
import '../../journeys/data/skin_journey_store.dart';

/// Riwayat scan. Sumber kebenaran adalah database (tabel `scan_records`) lewat
/// backend; daftar di memori hanya cache. Tanpa sesi login (mis. widget test)
/// perilakunya sama seperti sebelumnya: hanya di memori.
class SkinHistoryRepository extends ChangeNotifier implements CloudSyncable {
  SkinHistoryRepository._();
  static final SkinHistoryRepository instance = SkinHistoryRepository._();
  final List<SkinAnalysis> _records = [];

  ApiClient get _api => ApiClient.instance;

  Future<List<SkinAnalysis>> fetchHistory(
      {DateTime? date, bool newestFirst = true}) async {
    final result = _records
        .where((r) =>
            date == null ||
            (date.year == r.analyzedAt.year &&
                date.month == r.analyzedAt.month &&
                date.day == r.analyzedAt.day))
        .toList();
    result.sort((a, b) => newestFirst
        ? b.analyzedAt.compareTo(a.analyzedAt)
        : a.analyzedAt.compareTo(b.analyzedAt));
    return List.unmodifiable(result);
  }

  List<SkinAnalysis> get records => List.unmodifiable(_records);

  Future<SkinAnalysis> saveLatest(Uint8List? bytes,
      {List<String> findings = const [],
      String? skinType,
      bool modelConnected = false,
      bool isDemo = false,
      Map<String, int> detectionCounts = const {},
      Map<String, double> segmentationAreas = const {},
      Map<String, double> classConfidences = const {},
      double? skinTypeConfidence,
      String? modelVersion,
      String quality = 'unchecked',
      Rect? faceRect,
      List<SkinVisualBox> visualBoxes = const [],
      int? imageWidth,
      int? imageHeight}) async {
    final now = DateTime.now();
    final record = SkinAnalysis(
      id: 'scan-${now.microsecondsSinceEpoch}',
      analyzedAt: now,
      score: 0,
      oil: 0,
      pores: 0,
      acne: 0,
      redness: 0,
      title: (modelConnected || isDemo) && findings.isNotEmpty
          ? 'Temuan: ${findings.join(', ')}'
          : 'Foto pemantauan tersimpan',
      skinType: skinType ?? 'Belum diklasifikasikan',
      selfieBytes: bytes,
      visualFindings: findings,
      modelConnected: modelConnected,
      isDemo: isDemo,
      detectionCounts: detectionCounts,
      segmentationAreas: segmentationAreas,
      classConfidences: classConfidences,
      skinTypeConfidence: skinTypeConfidence,
      modelVersion: modelVersion,
      faceRect: faceRect,
      visualBoxes: visualBoxes,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
    _records.insert(0, record);
    if (bytes != null) {
      SkinJourneyStore.instance.addPhoto(bytes,
          visualFindings: findings,
          skinType: skinType,
          modelConnected: modelConnected,
          isDemo: isDemo,
          detectionCounts: detectionCounts,
          segmentationAreas: segmentationAreas,
          confidences: classConfidences,
          skinTypeConfidence: skinTypeConfidence,
          modelVersion: modelVersion,
          quality: quality,
          faceRect: faceRect,
          visualBoxes: visualBoxes,
          imageWidth: imageWidth,
          imageHeight: imageHeight);
    }
    notifyListeners();
    unawaited(_push(record, quality: quality));
    return record;
  }

  /// Hapus satu scan dari riwayat (lokal dan database).
  Future<void> delete(String id) async {
    final index = _records.indexWhere((r) => r.id == id);
    if (index < 0) return;
    final removed = _records.removeAt(index);
    notifyListeners();
    if (!_api.isAvailable) return;
    try {
      await _api.delete('/scan/history/$id');
      final path = removed.imagePath;
      if (path != null) await CloudStorage.remove([path]);
    } on Object catch (e) {
      debugPrint('Hapus scan di server gagal: $e');
    }
  }

  // ---------------------------------------------------------------- sync

  Future<void> _push(SkinAnalysis record, {String quality = 'unchecked'}) async {
    if (!_api.isAvailable) return;
    try {
      var path = record.imagePath;
      final bytes = record.selfieBytes;
      if (path == null && bytes != null) {
        path = await CloudStorage.upload('${record.id}.jpg', bytes);
        if (path != null) _replace(record.copyWith(imagePath: path));
      }
      final current = _records.firstWhere((r) => r.id == record.id,
          orElse: () => record);
      await _api.post('/scan/records',
          body: current.toApiJson(quality: quality));
    } on Object catch (e) {
      debugPrint('Simpan scan ke server gagal: $e');
    }
  }

  void _replace(SkinAnalysis updated) {
    final i = _records.indexWhere((r) => r.id == updated.id);
    if (i >= 0) _records[i] = updated;
  }

  @override
  Future<void> pullFromServer() async {
    if (!_api.isAvailable) return;
    final remote = <SkinAnalysis>[];
    var offset = 0;
    while (true) {
      final page = await _api.get('/scan/history',
          query: {'limit': 100, 'offset': offset}) as Map<String, dynamic>;
      final items = (page['items'] as List).cast<Map<String, dynamic>>();
      remote.addAll(items.map(SkinAnalysis.fromApiJson));
      offset += items.length;
      if (items.isEmpty || offset >= (page['total'] as int)) break;
    }

    final localById = {for (final r in _records) r.id: r};
    final remoteIds = {for (final r in remote) r.id};
    final merged = [
      for (final r in remote)
        r.copyWith(selfieBytes: localById[r.id]?.selfieBytes),
    ];
    // Scan yang dibuat saat offline dan belum ada di server: kirim sekarang.
    final unsynced = _records.where((r) => !remoteIds.contains(r.id)).toList();
    merged.addAll(unsynced);
    merged.sort((a, b) => b.analyzedAt.compareTo(a.analyzedAt));
    _records
      ..clear()
      ..addAll(merged);
    notifyListeners();

    for (final r in unsynced) {
      unawaited(_push(r));
    }
    unawaited(_downloadMissingPhotos());
  }

  Future<void> _downloadMissingPhotos() async {
    final pending = _records
        .where((r) => r.selfieBytes == null && r.imagePath != null)
        .toList();
    for (var i = 0; i < pending.length; i += 3) {
      final batch = pending.skip(i).take(3);
      await Future.wait([
        for (final r in batch)
          CloudStorage.download(r.imagePath!).then((bytes) {
            if (bytes != null) _replace(r.copyWith(selfieBytes: bytes));
          }),
      ]);
      notifyListeners();
    }
  }

  @override
  void clearLocal() {
    _records.clear();
    notifyListeners();
  }
}
