import 'dart:async';
import 'dart:ui' show Rect;
import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/cloud_storage.dart';
import '../../../core/api/cloud_sync.dart';
import '../../../core/api/supabase_direct.dart';
import '../../../core/cache/local_cache.dart';
import '../../scan/models/skin_analysis.dart';
import '../../journeys/data/skin_journey_store.dart';

/// Riwayat scan. Sumber kebenaran adalah database Supabase (tabel `scan_records`)
/// lewat backend FastAPI dengan fallback otomatis langsung ke Supabase SDK.
/// Daftar di memori hanya cache; tanpa sesi login (mis. widget test) perilakunya
/// hanya di memori.
class SkinHistoryRepository extends ChangeNotifier
    implements CloudSyncable, LocalCacheable {
  SkinHistoryRepository._() {
    addListener(_scheduleCacheSave);
  }
  static final SkinHistoryRepository instance = SkinHistoryRepository._();
  final List<SkinAnalysis> _records = [];
  final List<Future<void>> _inFlight = [];
  final Set<String> _pendingSyncIds = {};

  bool _isSyncing = false;
  bool _hasLoadedFromServer = false;
  Future<void>? _activePull;

  ApiClient get _api => ApiClient.instance;

  bool get _canSync => _api.isAvailable || SupabaseDirect.isSignedIn;
  bool get isSyncing => _isSyncing;
  bool get hasLoadedFromServer => _hasLoadedFromServer;

  void _track(Future<void> task) {
    _inFlight.add(task);
    task.whenComplete(() => _inFlight.remove(task));
  }

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

  /// Simpan hasil scan ke memori, ke Skin Journey aktif, dan tunggu penulisan
  /// ke Supabase/backend hingga selesai agar tidak hilang saat berpindah halaman.
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
    _pendingSyncIds.add(record.id);
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

    if (_canSync) {
      final task = _push(record, quality: quality);
      _track(task);
      await task;
    } else {
      _pendingSyncIds.remove(record.id);
    }
    return _records.firstWhere((r) => r.id == record.id, orElse: () => record);
  }

  /// Simpan hasil rekomendasi LLM ke dalam record scan (`meta.llm_recommendation`).
  Future<void> updateRecommendation(
    String scanId,
    Map<String, dynamic> recommendationJson,
  ) async {
    final index = _records.indexWhere((r) => r.id == scanId);
    if (index < 0) return;
    final updated =
        _records[index].copyWith(llmRecommendation: recommendationJson);
    _records[index] = updated;
    notifyListeners();

    if (!_canSync) return;
    final task = _pushMeta(updated);
    _track(task);
    await task;
  }

  Future<void> _pushMeta(SkinAnalysis record) async {
    final meta = record.buildMeta(
      quality: record.modelConnected ? 'pass' : 'unchecked',
    );
    if (_api.shouldAttemptBackend) {
      try {
        await _api.patch('/scan/history/${record.id}', body: {'meta': meta});
        return;
      } on Object catch (e) {
        debugPrint(
            'Simpan meta scan via backend gagal, fallback ke Supabase: $e');
      }
    }
    try {
      await SupabaseDirect.updateScanRecord(record.id, {'meta': meta});
    } on Object catch (e) {
      debugPrint('Simpan meta scan ke Supabase gagal: $e');
    }
  }

  /// Hapus satu scan dari riwayat (lokal dan database).
  Future<void> delete(String id) async {
    final index = _records.indexWhere((r) => r.id == id);
    if (index < 0) return;
    final removed = _records.removeAt(index);
    _pendingSyncIds.remove(id);
    notifyListeners();
    if (!_canSync) return;
    final task = _deleteRemote(removed);
    _track(task);
    await task;
  }

  Future<void> _deleteRemote(SkinAnalysis removed) async {
    var deletedOnBackend = false;
    if (_api.shouldAttemptBackend) {
      try {
        await _api.delete('/scan/history/${removed.id}');
        deletedOnBackend = true;
      } on Object catch (e) {
        debugPrint('Hapus scan di backend gagal, fallback ke Supabase: $e');
      }
    }
    if (!deletedOnBackend) {
      try {
        await SupabaseDirect.deleteScanRecord(removed.id);
      } on Object catch (e) {
        debugPrint('Hapus scan di Supabase gagal: $e');
      }
    }
    final path = removed.imagePath;
    if (path != null) await CloudStorage.remove([path]);
  }

  // ---------------------------------------------------------------- sync

  Future<void> _push(SkinAnalysis record, {String quality = 'unchecked'}) async {
    if (!_canSync) return;
    try {
      var path = record.imagePath;
      final bytes = record.selfieBytes;
      if (path == null && bytes != null) {
        path = await CloudStorage.upload('${record.id}.jpg', bytes);
        if (path != null) _replace(record.copyWith(imagePath: path));
      }
      final current = _records.firstWhere((r) => r.id == record.id,
          orElse: () => record);
      final body = current.toApiJson(quality: quality);

      if (_api.shouldAttemptBackend) {
        try {
          await _api.post('/scan/records', body: body);
          _pendingSyncIds.remove(record.id);
          return;
        } on Object catch (e) {
          debugPrint('Simpan scan via backend gagal, fallback ke Supabase: $e');
        }
      }
      await SupabaseDirect.upsertScanRecord(body);
      _pendingSyncIds.remove(record.id);
    } on Object catch (e) {
      debugPrint('Simpan scan ke server gagal: $e');
    }
  }

  void _replace(SkinAnalysis updated) {
    final i = _records.indexWhere((r) => r.id == updated.id);
    if (i >= 0) _records[i] = updated;
  }

  @override
  Future<void> flushPending() async {
    if (_inFlight.isNotEmpty) {
      await Future.wait(List<Future<void>>.of(_inFlight));
    }
    if (_pendingSyncIds.isNotEmpty && _canSync) {
      final pending = _records
          .where((r) => _pendingSyncIds.contains(r.id))
          .toList(growable: false);
      for (final r in pending) {
        await _push(r, quality: r.modelConnected ? 'pass' : 'unchecked');
      }
    }
  }

  @override
  Future<void> pullFromServer() async {
    if (!_canSync) return;
    if (_activePull != null) return _activePull!;
    final completer = Completer<void>();
    _activePull = completer.future;
    _isSyncing = true;
    notifyListeners();
    try {
      List<SkinAnalysis>? remote;

      if (_api.shouldAttemptBackend) {
        try {
          final collected = <SkinAnalysis>[];
          var offset = 0;
          while (true) {
            final page = await _api.get('/scan/history',
                query: {'limit': 100, 'offset': offset}) as Map<String, dynamic>;
            final items = (page['items'] as List).cast<Map<String, dynamic>>();
            collected.addAll(items.map(SkinAnalysis.fromApiJson));
            offset += items.length;
            if (items.isEmpty || offset >= (page['total'] as int)) break;
          }
          remote = collected;
        } on Object catch (e) {
          debugPrint(
              'Tarik riwayat scan via backend gagal, fallback ke Supabase: $e');
        }
      }

      if (remote == null && SupabaseDirect.isSignedIn) {
        final rows = await SupabaseDirect.fetchScanHistory();
        remote = rows.map(SkinAnalysis.fromApiJson).toList();
      }
      if (remote == null) return;

      final localById = {for (final r in _records) r.id: r};
      final remoteIds = {for (final r in remote) r.id};
      final merged = [
        for (final r in remote)
          r.copyWith(selfieBytes: localById[r.id]?.selfieBytes),
      ];
      // Scan lokal yang belum ada di server (mis. dibuat saat offline): pertahankan & kirim ulang.
      // Scan yang tidak ada di server dan tidak tertunda berarti sudah dihapus
      // di perangkat lain (mis. berasal dari cache), jadi tidak dihidupkan lagi.
      final unsynced = _records
          .where((r) =>
              !remoteIds.contains(r.id) && _pendingSyncIds.contains(r.id))
          .toList();
      merged.addAll(unsynced);
      merged.sort((a, b) => b.analyzedAt.compareTo(a.analyzedAt));
      _records
        ..clear()
        ..addAll(merged);
      _hasLoadedFromServer = true;
      notifyListeners();

      for (final r in unsynced) {
        _pendingSyncIds.add(r.id);
        _track(_push(r, quality: r.modelConnected ? 'pass' : 'unchecked'));
      }
      unawaited(_downloadMissingPhotos());
    } finally {
      _isSyncing = false;
      _activePull = null;
      if (!completer.isCompleted) completer.complete();
      notifyListeners();
    }
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

  // ---------------------------------------------------------------- cache

  static const _cacheName = 'scan_history';
  Timer? _cacheTimer;
  bool _restoringCache = false;
  final Set<String> _cachedPhotoIds = {};

  void _scheduleCacheSave() {
    if (_restoringCache || !LocalCache.instance.isActive) return;
    _cacheTimer?.cancel();
    _cacheTimer = Timer(
        const Duration(milliseconds: 600), () => unawaited(_saveCache()));
  }

  Future<void> _saveCache() async {
    final cache = LocalCache.instance;
    if (!cache.isActive) return;
    final snapshot = List<SkinAnalysis>.of(_records);
    await cache.writeJson(_cacheName, {
      'pending': _pendingSyncIds.toList(),
      'records': [
        for (final r in snapshot)
          r.toApiJson(quality: r.modelConnected ? 'pass' : 'unchecked'),
      ],
    });
    final current = <String>{};
    for (final r in snapshot) {
      current.add(r.id);
      final bytes = r.selfieBytes;
      if (bytes == null || _cachedPhotoIds.contains(r.id)) continue;
      await cache.writeBytes('scans/${r.id}.jpg', bytes);
      _cachedPhotoIds.add(r.id);
    }
    for (final id in _cachedPhotoIds.difference(current).toList()) {
      await cache.deleteFile('scans/$id.jpg');
      _cachedPhotoIds.remove(id);
    }
  }

  @override
  Future<void> loadFromCache() async {
    final cache = LocalCache.instance;
    final data = await cache.readJson(_cacheName);
    if (data == null) return;
    final restored = <SkinAnalysis>[];
    for (final json
        in ((data['records'] as List?) ?? const []).cast<Map<String, dynamic>>()) {
      try {
        var record = SkinAnalysis.fromApiJson(json);
        final bytes = await cache.readBytes('scans/${record.id}.jpg');
        if (bytes != null) {
          record = record.copyWith(selfieBytes: bytes);
          _cachedPhotoIds.add(record.id);
        }
        restored.add(record);
      } on Object catch (e) {
        debugPrint('Lewati scan cache yang rusak: $e');
      }
    }
    _restoringCache = true;
    try {
      final known = {for (final r in _records) r.id};
      _records.addAll(restored.where((r) => !known.contains(r.id)));
      _records.sort((a, b) => b.analyzedAt.compareTo(a.analyzedAt));
      _pendingSyncIds
          .addAll(((data['pending'] as List?) ?? const []).cast<String>());
      notifyListeners();
    } finally {
      _restoringCache = false;
    }
  }

  @override
  void clearLocal() {
    _cacheTimer?.cancel();
    _cachedPhotoIds.clear();
    _records.clear();
    _pendingSyncIds.clear();
    _hasLoadedFromServer = false;
    _isSyncing = false;
    notifyListeners();
  }
}
