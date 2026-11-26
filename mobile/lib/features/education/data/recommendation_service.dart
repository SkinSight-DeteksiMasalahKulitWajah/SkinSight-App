import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/api/api_client.dart';

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

  Map<String, dynamic> toJson() => {
        'finding': finding,
        'finding_label': findingLabel,
        'explanation': explanation,
        'care_tips': careTips,
        'timeline': timeline,
      };

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

  Map<String, dynamic> toJson() => {
        'order': order,
        'step_name': stepName,
        'description': description,
        'ingredient_highlights': ingredientHighlights,
        'when': when,
      };

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

  Map<String, dynamic> toJson() => {
        'summary': summary,
        'skin_type_note': skinTypeNote,
        'findings_education':
            findingsEducation.map((e) => e.toJson()).toList(),
        'routine': routine.map((e) => e.toJson()).toList(),
        'recommended_ingredients': recommendedIngredients,
        'avoid_ingredients': avoidIngredients,
        'lifestyle_tips': lifestyleTips,
        'medical_warning': medicalWarning,
        'disclaimer': disclaimer,
      };

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
/// Memakai `ApiClient.instance.baseUrl` yang sudah dinormalisasi (`/api/v1`)
/// agar konsisten dengan seluruh endpoint CRUD backend.
class RecommendationService {
  RecommendationService._();
  static final instance = RecommendationService._();

  /// Meminta rekomendasi perawatan kulit ke backend LLM endpoint.
  ///
  /// [scanData] berisi hasil scan wajah on-device.
  /// [quizAnswers] berisi jawaban kuesioner M01–M07.
  /// [checkinHistory] berisi riwayat check-in mingguan (opsional).
  ///
  /// Bila backend baru saja gagal dihubungi, langsung gagal tanpa menunggu,
  /// kecuali [force] (tombol muat ulang / coba lagi dari pengguna).
  Future<RecommendationResult> getRecommendation({
    required Map<String, dynamic> scanData,
    Map<String, String> quizAnswers = const {},
    List<Map<String, dynamic>> checkinHistory = const [],
    bool force = false,
  }) async {
    final api = ApiClient.instance;
    if (force) {
      api.resetCircuitBreaker();
    } else if (!api.isReachableNow) {
      throw Exception(
          'Server rekomendasi sedang tidak terjangkau. Coba lagi nanti.');
    }
    final base = api.baseUrl;
    final uri = Uri.parse('$base/recommendation/generate');
    final token = ApiClient.instance.accessToken;

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
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 20));

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
      // Tidak menandai server mati: AI bisa saja hanya lambat menjawab.
      throw Exception(
          'Koneksi ke server timeout. Periksa koneksi internet.');
    } on http.ClientException catch (e) {
      // Gagal tersambung sama sekali: lewati percobaan berikutnya selama cooldown.
      api.markUnreachable();
      throw Exception('Gagal menghubungi server rekomendasi: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal menghubungi server rekomendasi: $e');
    }
  }

  /// Konversi quiz answers dari format mobile (`Map<String, String>`)
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
