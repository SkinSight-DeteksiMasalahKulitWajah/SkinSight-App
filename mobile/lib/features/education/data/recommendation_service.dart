import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Model data untuk satu edukasi temuan dari LLM.
class FindingEducation {
  final String finding;
  final String findingLabel;
  final String explanation;
  final List<String> careTips;
  final String timeline;

  const FindingEducation({
    required this.finding,
    required this.findingLabel,
    required this.explanation,
    required this.careTips,
    required this.timeline,
  });

  factory FindingEducation.fromJson(Map<String, dynamic> json) =>
      FindingEducation(
        finding: json['finding'] as String? ?? '',
        findingLabel: json['finding_label'] as String? ?? '',
        explanation: json['explanation'] as String? ?? '',
        careTips: (json['care_tips'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        timeline: json['timeline'] as String? ?? '',
      );
}

/// Model data untuk satu langkah rutinitas perawatan.
class RoutineStep {
  final int order;
  final String stepName;
  final String description;
  final List<String> ingredientHighlights;
  final String when;

  const RoutineStep({
    required this.order,
    required this.stepName,
    required this.description,
    required this.ingredientHighlights,
    required this.when,
  });

  factory RoutineStep.fromJson(Map<String, dynamic> json) => RoutineStep(
        order: json['order'] as int? ?? 0,
        stepName: json['step_name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        ingredientHighlights: (json['ingredient_highlights'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        when: json['when'] as String? ?? 'pagi & malam',
      );
}

/// Hasil rekomendasi lengkap dari LLM.
class RecommendationResult {
  final String summary;
  final String skinTypeNote;
  final List<FindingEducation> findingsEducation;
  final List<RoutineStep> routine;
  final List<String> recommendedIngredients;
  final List<String> avoidIngredients;
  final List<String> lifestyleTips;
  final String? medicalWarning;
  final String disclaimer;

  const RecommendationResult({
    required this.summary,
    required this.skinTypeNote,
    required this.findingsEducation,
    required this.routine,
    required this.recommendedIngredients,
    required this.avoidIngredients,
    required this.lifestyleTips,
    this.medicalWarning,
    required this.disclaimer,
  });

  factory RecommendationResult.fromJson(Map<String, dynamic> json) =>
      RecommendationResult(
        summary: json['summary'] as String? ?? '',
        skinTypeNote: json['skin_type_note'] as String? ?? '',
        findingsEducation: (json['findings_education'] as List?)
                ?.map((e) =>
                    FindingEducation.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        routine: (json['routine'] as List?)
                ?.map(
                    (e) => RoutineStep.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        recommendedIngredients: (json['recommended_ingredients'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        avoidIngredients: (json['avoid_ingredients'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        lifestyleTips: (json['lifestyle_tips'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        medicalWarning: json['medical_warning'] as String?,
        disclaimer: json['disclaimer'] as String? ??
            'Hasil ini bukan diagnosis medis.',
      );
}

/// Service untuk memanggil endpoint rekomendasi LLM di backend.
class RecommendationService {
  RecommendationService._();
  static final instance = RecommendationService._();

  /// Ganti dengan URL backend Anda.
  /// Untuk emulator Android: http://10.0.2.2:8000
  /// Untuk device fisik: IP lokal atau URL production.
  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// Meminta rekomendasi perawatan kulit ke backend LLM endpoint.
  ///
  /// [scanData] berisi hasil scan wajah on-device.
  /// [quizAnswers] berisi jawaban kuesioner M01–M07.
  /// [checkinHistory] berisi riwayat check-in mingguan (opsional).
  Future<RecommendationResult> getRecommendation({
    required Map<String, dynamic> scanData,
    Map<String, String> quizAnswers = const {},
    List<Map<String, dynamic>> checkinHistory = const [],
  }) async {
    final uri =
        Uri.parse('$_baseUrl/api/v1/recommendation/generate');

    final body = jsonEncode({
      'scan': scanData,
      'quiz': _mapQuizAnswers(quizAnswers),
      'checkin_history': checkinHistory,
      'language': 'id',
    });

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>;
        return RecommendationResult.fromJson(data);
      } else {
        throw Exception(
          'Server error ${response.statusCode}: ${response.body}',
        );
      }
    } on TimeoutException {
      throw Exception(
          'Koneksi ke server timeout. Periksa koneksi internet.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal menghubungi server rekomendasi: $e');
    }
  }

  /// Konversi quiz answers dari format mobile (Map<String, String>)
  /// ke format yang diharapkan backend.
  Map<String, String?> _mapQuizAnswers(Map<String, String> answers) => {
        'M01': answers['M01'],
        'M02': answers['M02'],
        'M03': answers['M03'],
        'M04': answers['M04'],
        'M05': answers['M05'],
        'M06': answers['M06'],
        'M07': answers['M07'],
        'regimen_name': answers['regimen_name'],
        'regimen_class': answers['regimen_class'],
        'regimen_start': answers['regimen_start'],
      };

  /// Helper: bangun scanData map dari SkinAnalysis object.
  static Map<String, dynamic> scanDataFromAnalysis({
    required String skinType,
    double? skinTypeConfidence,
    List<String> visualFindings = const [],
    Map<String, int> detectionCounts = const {},
    Map<String, double> segmentationAreas = const {},
    Map<String, double> classConfidences = const {},
  }) =>
      {
        'skin_type': skinType,
        'skin_type_confidence': skinTypeConfidence,
        'visual_findings': visualFindings,
        'detection_counts': detectionCounts,
        'segmentation_areas': segmentationAreas,
        'class_confidences': classConfidences,
      };
}
