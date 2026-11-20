import 'package:flutter_test/flutter_test.dart';
import 'package:skinsight/core/api/api_client.dart';
import 'package:skinsight/core/api/supabase_direct.dart';
import 'package:skinsight/features/education/data/recommendation_service.dart';
import 'package:skinsight/features/scan/models/skin_analysis.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

User _fakeGoogleUser({
  String id = '00000000-0000-0000-0000-000000000001',
  String? email = 'ibra.dev@gmail.com',
  Map<String, dynamic>? metadata,
}) {
  return User(
    id: id,
    appMetadata: const {'provider': 'google'},
    userMetadata: metadata,
    aud: 'authenticated',
    createdAt: '2026-11-20T00:00:00.000Z',
    email: email,
  );
}

void main() {
  group('normalizeApiBaseUrl', () {
    test('appends /api/v1 when missing and never duplicates', () {
      expect(
        normalizeApiBaseUrl('http://10.0.2.2:8000'),
        'http://10.0.2.2:8000/api/v1',
      );
      expect(
        normalizeApiBaseUrl('http://10.0.2.2:8000/'),
        'http://10.0.2.2:8000/api/v1',
      );
      expect(
        normalizeApiBaseUrl('http://192.168.1.10:8000/api/v1'),
        'http://192.168.1.10:8000/api/v1',
      );
      expect(
        normalizeApiBaseUrl('https://api.skinsight.id/api/v1/'),
        'https://api.skinsight.id/api/v1',
      );
    });
  });

  group('Google OAuth display name & avatar extraction', () {
    test('prefers Google full_name and picture over placeholder names', () {
      final user = _fakeGoogleUser(metadata: {
        'full_name': 'Muchammad Ibrahim',
        'picture': 'https://lh3.googleusercontent.com/a/photo',
      });
      expect(SupabaseDirect.extractDisplayName(user), 'Muchammad Ibrahim');
      expect(
        SupabaseDirect.extractAvatarUrl(user),
        'https://lh3.googleusercontent.com/a/photo',
      );
    });

    test('falls back to given_name + family_name then email prefix', () {
      final withGiven = _fakeGoogleUser(metadata: {
        'given_name': 'Bintang',
        'family_name': 'Dev',
      });
      expect(SupabaseDirect.extractDisplayName(withGiven), 'Bintang Dev');

      final emailOnly = _fakeGoogleUser(email: 'rafazl@gmail.com', metadata: {});
      expect(SupabaseDirect.extractDisplayName(emailOnly), 'rafazl');
    });

    test('identifies Alea Kucing and Pengguna SkinSight as placeholders', () {
      expect(SupabaseDirect.isPlaceholderName('Alea Kucing'), isTrue);
      expect(SupabaseDirect.isPlaceholderName('Pengguna SkinSight'), isTrue);
      expect(SupabaseDirect.isPlaceholderName(''), isTrue);
      expect(SupabaseDirect.isPlaceholderName('Muchammad Ibrahim'), isFalse);
    });
  });

  group('SkinAnalysis + LLM Recommendation persistence serialization', () {
    test('round-trips llm_recommendation through meta JSON', () {
      const rec = RecommendationResult(
        summary: 'Kulit kombinasi dengan jerawat ringan.',
        skinTypeNote: 'Gunakan pelembap gel.',
        findingsEducation: [
          FindingEducation(
            finding: 'Acne',
            findingLabel: 'Jerawat',
            explanation: 'Jaga kebersihan pori.',
            careTips: ['Cuci wajah lembut 2x sehari'],
            timeline: '6-8 minggu',
          ),
        ],
        routine: [
          RoutineStep(
            order: 1,
            stepName: 'Cleanser',
            description: 'Pembersih lembut',
            ingredientHighlights: ['Niacinamide'],
            when: 'pagi & malam',
          ),
        ],
        recommendedIngredients: ['Niacinamide'],
        avoidIngredients: ['Scrub kasar'],
        lifestyleTips: ['Tidur cukup'],
        medicalWarning: null,
        disclaimer: 'Bukan diagnosis medis.',
      );

      final analysis = SkinAnalysis(
        id: 'scan-001',
        analyzedAt: DateTime.utc(2026, 11, 20, 7, 0),
        score: 85,
        title: 'Temuan: Acne',
        skinType: 'Combination',
        oil: 30,
        pores: 20,
        acne: 25,
        redness: 10,
        visualFindings: const ['Acne'],
        modelConnected: true,
        detectionCounts: const {'Acne': 2},
        classConfidences: const {'Acne': 0.84},
        imagePath: 'user-1/scan-001.jpg',
        llmRecommendation: rec.toJson(),
      );

      final restored = SkinAnalysis.fromApiJson(analysis.toApiJson(quality: 'pass'));
      expect(restored.id, 'scan-001');
      expect(restored.imagePath, 'user-1/scan-001.jpg');
      expect(restored.llmRecommendation, isNotNull);

      final restoredRec = RecommendationResult.fromJson(restored.llmRecommendation!);
      expect(restoredRec.summary, rec.summary);
      expect(restoredRec.routine.single.stepName, 'Cleanser');
      expect(restoredRec.findingsEducation.single.finding, 'Acne');
    });
  });
}
