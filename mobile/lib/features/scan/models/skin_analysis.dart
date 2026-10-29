import 'dart:typed_data';

class SkinAnalysis {
  final String id;
  final DateTime analyzedAt;
  final int score;
  final String title;
  final String skinType;
  final int oil;
  final int pores;
  final int acne;
  final int redness;
  final Uint8List? selfieBytes;
  final List<String> visualFindings;
  final bool modelConnected;
  final bool isDemo;

  /// Output asli inferensi: 3 kelas detection berupa jumlah bounding box.
  final Map<String, int> detectionCounts;

  /// 2 kelas segmentation: rasio mask terhadap area wajah valid (0..1).
  final Map<String, double> segmentationAreas;
  final Map<String, double> classConfidences;
  final double? skinTypeConfidence;
  final String? modelVersion;

  const SkinAnalysis({
    required this.id,
    required this.analyzedAt,
    required this.score,
    required this.title,
    required this.skinType,
    required this.oil,
    required this.pores,
    required this.acne,
    required this.redness,
    this.selfieBytes,
    this.visualFindings = const [],
    this.modelConnected = false,
    this.isDemo = false,
    this.detectionCounts = const {},
    this.segmentationAreas = const {},
    this.classConfidences = const {},
    this.skinTypeConfidence,
    this.modelVersion,
  });

  SkinAnalysis copyWith({Uint8List? selfieBytes}) {
    return SkinAnalysis(
      id: id,
      analyzedAt: analyzedAt,
      score: score,
      title: title,
      skinType: skinType,
      oil: oil,
      pores: pores,
      acne: acne,
      redness: redness,
      selfieBytes: selfieBytes ?? this.selfieBytes,
      visualFindings: visualFindings,
      modelConnected: modelConnected,
      isDemo: isDemo,
      detectionCounts: detectionCounts,
      segmentationAreas: segmentationAreas,
      classConfidences: classConfidences,
      skinTypeConfidence: skinTypeConfidence,
      modelVersion: modelVersion,
    );
  }
}
