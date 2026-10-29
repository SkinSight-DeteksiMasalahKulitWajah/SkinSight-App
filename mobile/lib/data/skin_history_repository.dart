import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/skin_analysis.dart';
import 'skin_journey_store.dart';

/// Real user actions only; no preloaded fake scores or skin findings.
/// In-memory MVP demo; persistent storage is a backend integration task.
class SkinHistoryRepository extends ChangeNotifier {
  SkinHistoryRepository._();
  static final SkinHistoryRepository instance = SkinHistoryRepository._();
  final List<SkinAnalysis> _records = [];

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
      String quality = 'unchecked'}) async {
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
          quality: quality);
    }
    notifyListeners();
    return record;
  }
}
