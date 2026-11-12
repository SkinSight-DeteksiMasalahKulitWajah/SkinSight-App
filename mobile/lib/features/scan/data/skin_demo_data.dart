import 'dart:typed_data';
import 'dart:ui' show Rect;

import '../models/skin_analysis.dart';

/// Data ilustratif khusus DEMO UI. Tidak membaca konten foto / memanggil ML.
/// Nilai yang sama ditampilkan pada Hasil dan disimpan ke Skin Journey.
abstract final class SkinDemoData {
  static SkinAnalysis forPhoto(Uint8List bytes, {int sessionIndex = 0}) {
    // Sesi berbeda dapat memiliki sedikit variasi ilustratif.
    final variation = sessionIndex % 3;
    final counts = <String, int>{
      'Acne': 4 + variation,
      'PIH': 3 + (variation == 2 ? 1 : 0),
      'Dark Circle': 2,
    };
    final areas = <String, double>{
      'Redness': 0.09 + variation * 0.01,
      'Wrinkle': 0.00,
    };
    return SkinAnalysis(
      id: 'demo-${DateTime.now().microsecondsSinceEpoch}',
      analyzedAt: DateTime.now(),
      selfieBytes: bytes,
      score: 0,
      oil: 0,
      pores: 0,
      acne: 0,
      redness: 0,
      title: 'Hasil pemeriksaan visual',
      skinType: 'Dry',
      skinTypeConfidence: .86,
      visualFindings: const ['Acne', 'PIH', 'Dark Circle', 'Redness'],
      modelConnected: false,
      isDemo: true,
      detectionCounts: counts,
      segmentationAreas: areas,
      classConfidences: const {
        'Acne': .88,
        'PIH': .83,
        'Dark Circle': .77,
        'Redness': .81,
        'Wrinkle': .69,
      },
      modelVersion: 'demo-ui-v1',
      faceRect: const Rect.fromLTWH(0.24, 0.16, 0.52, 0.58),
      visualBoxes: const [
        SkinVisualBox(
          label: 'Acne',
          score: 0.88,
          normalizedRect: Rect.fromLTWH(0.48, 0.32, 0.06, 0.06),
        ),
        SkinVisualBox(
          label: 'Acne',
          score: 0.82,
          normalizedRect: Rect.fromLTWH(0.36, 0.44, 0.05, 0.05),
        ),
        SkinVisualBox(
          label: 'PIH',
          score: 0.83,
          normalizedRect: Rect.fromLTWH(0.58, 0.46, 0.05, 0.05),
        ),
        SkinVisualBox(
          label: 'Dark Circle',
          score: 0.77,
          normalizedRect: Rect.fromLTWH(0.36, 0.38, 0.12, 0.05),
        ),
        SkinVisualBox(
          label: 'Redness',
          score: 0.81,
          normalizedRect: Rect.fromLTWH(0.44, 0.46, 0.12, 0.10),
        ),
      ],
      imageWidth: 1200,
      imageHeight: 1600,
    );
  }
}
