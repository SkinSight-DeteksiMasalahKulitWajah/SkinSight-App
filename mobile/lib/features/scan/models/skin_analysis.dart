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

  /// Path foto di Supabase Storage (`<user_id>/<file>`), null bila belum diunggah.
  final String? imagePath;

  /// Cache JSON hasil rekomendasi LLM terakhir untuk scan ini (disimpan di `meta`).
  final Map<String, dynamic>? llmRecommendation;

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
    this.imagePath,
    this.llmRecommendation,
  });

  SkinAnalysis copyWith({
    Uint8List? selfieBytes,
    Rect? faceRect,
    List<SkinVisualBox>? visualBoxes,
    int? imageWidth,
    int? imageHeight,
    String? imagePath,
    Map<String, dynamic>? llmRecommendation,
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
      imagePath: imagePath ?? this.imagePath,
      llmRecommendation: llmRecommendation ?? this.llmRecommendation,
    );
  }

  Map<String, dynamic> buildMeta({String quality = 'unchecked'}) => {
        'skin_type_confidence': skinTypeConfidence,
        'quality': quality,
        'image_width': imageWidth,
        'image_height': imageHeight,
        if (faceRect != null)
          'face_rect': [
            faceRect!.left,
            faceRect!.top,
            faceRect!.right,
            faceRect!.bottom,
          ],
        'visual_boxes': [for (final b in visualBoxes) b.toJson()],
        if (llmRecommendation != null) 'llm_recommendation': llmRecommendation,
      };

  /// Payload untuk `POST /scan/records` di backend.
  Map<String, dynamic> toApiJson({String quality = 'unchecked'}) => {
        'id': id,
        'analyzed_at': analyzedAt.toUtc().toIso8601String(),
        'image_url': imagePath,
        'score': score,
        'title': title,
        'skin_type': skinType,
        'oil': oil,
        'pores': pores,
        'acne': acne,
        'redness': redness,
        'visual_findings': visualFindings,
        'detection_counts': detectionCounts,
        'segmentation_areas': segmentationAreas,
        'class_confidences': classConfidences,
        'model_version': modelVersion,
        'model_connected': modelConnected,
        'is_demo': isDemo,
        'meta': buildMeta(quality: quality),
      };

  /// Membangun dari respons backend (`ScanRecordOut`); foto belum terunduh.
  factory SkinAnalysis.fromApiJson(Map<String, dynamic> json) {
    final meta = (json['meta'] as Map?)?.cast<String, dynamic>() ?? const {};
    final face = (meta['face_rect'] as List?)?.cast<num>();
    final rawRec = meta['llm_recommendation'];
    return SkinAnalysis(
      id: json['id'] as String,
      analyzedAt: DateTime.parse(json['analyzed_at'] as String).toLocal(),
      score: (json['score'] as num?)?.toInt() ?? 0,
      title: json['title'] as String,
      skinType: json['skin_type'] as String,
      oil: (json['oil'] as num?)?.toInt() ?? 0,
      pores: (json['pores'] as num?)?.toInt() ?? 0,
      acne: (json['acne'] as num?)?.toInt() ?? 0,
      redness: (json['redness'] as num?)?.toInt() ?? 0,
      visualFindings:
          ((json['visual_findings'] as List?) ?? const []).cast<String>(),
      modelConnected: json['model_connected'] as bool? ?? false,
      isDemo: json['is_demo'] as bool? ?? false,
      detectionCounts: {
        for (final e in ((json['detection_counts'] as Map?) ?? const {}).entries)
          e.key as String: (e.value as num).toInt(),
      },
      segmentationAreas: {
        for (final e
            in ((json['segmentation_areas'] as Map?) ?? const {}).entries)
          e.key as String: (e.value as num).toDouble(),
      },
      classConfidences: {
        for (final e in ((json['class_confidences'] as Map?) ?? const {}).entries)
          e.key as String: (e.value as num).toDouble(),
      },
      skinTypeConfidence: (meta['skin_type_confidence'] as num?)?.toDouble(),
      modelVersion: json['model_version'] as String?,
      faceRect: face == null || face.length < 4
          ? null
          : Rect.fromLTRB(face[0].toDouble(), face[1].toDouble(),
              face[2].toDouble(), face[3].toDouble()),
      visualBoxes: [
        for (final b in (meta['visual_boxes'] as List?) ?? const [])
          SkinVisualBox.fromJson((b as Map).cast<String, dynamic>()),
      ],
      imageWidth: (meta['image_width'] as num?)?.toInt(),
      imageHeight: (meta['image_height'] as num?)?.toInt(),
      imagePath: json['image_url'] as String?,
      llmRecommendation:
          rawRec is Map ? Map<String, dynamic>.from(rawRec) : null,
    );
  }
}
