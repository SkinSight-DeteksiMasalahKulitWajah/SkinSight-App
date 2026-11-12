import 'dart:typed_data';
import 'dart:ui' show Rect;

/// Representasi satu kotak atau lingkaran deteksi visual pada wajah.
/// [normalizedRect] bernilai 0..1 terhadap lebar dan tinggi foto asli.
class SkinVisualBox {
  final String label;
  final double score;
  final Rect normalizedRect;

  const SkinVisualBox({
    required this.label,
    required this.score,
    required this.normalizedRect,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'score': score,
        'rect': [
          normalizedRect.left,
          normalizedRect.top,
          normalizedRect.right,
          normalizedRect.bottom,
        ],
      };

  factory SkinVisualBox.fromJson(Map<String, dynamic> json) {
    final r = (json['rect'] as List).cast<num>();
    return SkinVisualBox(
      label: json['label'] as String,
      score: (json['score'] as num).toDouble(),
      normalizedRect: Rect.fromLTRB(
        r[0].toDouble(),
        r[1].toDouble(),
        r[2].toDouble(),
        r[3].toDouble(),
      ),
    );
  }
}

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

  /// Koordinat area wajah terdeteksi (Face ROI) ternormalisasi (0..1).
  final Rect? faceRect;

  /// Lokasi deteksi individual (lingkaran / box jerawat, flek, kerutan, dll.) (0..1).
  final List<SkinVisualBox> visualBoxes;

  /// Dimensi asli foto untuk scaling tepat pada layar.
  final int? imageWidth;
  final int? imageHeight;

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
    this.faceRect,
    this.visualBoxes = const [],
    this.imageWidth,
    this.imageHeight,
  });

  SkinAnalysis copyWith({
    Uint8List? selfieBytes,
    Rect? faceRect,
    List<SkinVisualBox>? visualBoxes,
    int? imageWidth,
    int? imageHeight,
  }) {
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
      faceRect: faceRect ?? this.faceRect,
      visualBoxes: visualBoxes ?? this.visualBoxes,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
    );
  }
}
