import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:skinsight/core/api/api_client.dart';
import 'package:skinsight/core/api/supabase_direct.dart';
import 'package:skinsight/core/theme/skin_theme.dart';
import 'package:skinsight/features/education/data/recommendation_service.dart';
import 'package:skinsight/features/history/data/skin_history_repository.dart';
import 'package:skinsight/features/history/presentation/skin_history_page.dart';
import 'package:skinsight/features/journeys/data/skin_journey_store.dart';
import 'package:skinsight/features/profile/models/profile_data.dart';
import 'package:skinsight/features/profile/presentation/skin_account_page.dart';
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

  group('ApiClient circuit-breaker & consecutive scan persistence', () {
    test('circuit-breaker trips on connection failure and resets cleanly', () async {
      final failingHttp = MockClient((_) async {
        throw http.ClientException('Connection refused');
      });
      final api = ApiClient(
        client: failingHttp,
        baseUrl: 'http://10.0.2.2:8000',
        tokenProvider: () => 'fake-token',
      );
      expect(api.shouldAttemptBackend, isTrue);

      await expectLater(api.get('/health'), throwsA(isA<ApiException>()));
      // Setelah gagal koneksi, langsung skip backend (0ms) agar fallback ke Supabase cepat.
      expect(api.shouldAttemptBackend, isFalse);

      api.resetCircuitBreaker();
      expect(api.shouldAttemptBackend, isTrue);
    });

    test('consecutive scans on new draft journey all save and become visible', () async {
      final store = SkinJourneyStore.instance..resetForTesting();
      final history = SkinHistoryRepository.instance..clearLocal();
      addTearDown(() {
        store.resetForTesting();
        history.clearLocal();
      });

      // Mulai perjalanan baru (awalnya isDraft = true) lalu isi kuesioner.
      store.beginNewJourney(name: 'Uji Berturut');
      store.saveQuestionnaire({
        'M01': 'Tidak',
        'M02': 'Rutin',
        'M03': 'Tidak',
        'M04': 'Tidak',
        'M05': 'Rutin',
        'M06': 'Tidak',
        'M07': 'Acne',
      }, photoConsent: true);

      final sampleBytes = Uint8List.fromList([137, 80, 78, 71]);
      for (var i = 0; i < 3; i++) {
        await history.saveLatest(
          sampleBytes,
          findings: const ['Acne'],
          skinType: 'Combination',
          modelConnected: true,
          detectionCounts: {'Acne': i + 1},
          quality: 'pass',
        );
      }

      expect(history.records.length, 3);
      expect(store.selectedJourney.isDraft, isFalse);
      expect(store.selectedJourney.isVisibleInCatalog, isTrue);
      expect(store.photos.length, 3);
      expect(store.journeys.any((j) => j.name == 'Uji Berturut'), isTrue);
    });

    testWidgets(
      'redesigned history shows localized Indonesian badges and deletes with confirmation',
      (tester) async {
        final history = SkinHistoryRepository.instance..clearLocal();
        final store = SkinJourneyStore.instance..resetForTesting();
        addTearDown(() {
          history.clearLocal();
          store.resetForTesting();
        });

        final saved = await history.saveLatest(
          null,
          findings: const ['Acne', 'PIH'],
          skinType: 'Combination',
          modelConnected: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: SkinTokens.theme(),
            home: const SkinHistoryPage(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Jerawat & Noda Gelap (PIH)'), findsOneWidget);
        expect(find.text('2 temuan'), findsOneWidget);
        expect(find.text('Kombinasi'), findsOneWidget);

        await tester.tap(find.byKey(Key('history-delete-${saved.id}')));
        await tester.pumpAndSettle();
        expect(find.text('Hapus riwayat scan?'), findsOneWidget);

        await tester.tap(find.byKey(const Key('confirm-delete-scan')));
        await tester.pumpAndSettle();

        expect(history.records, isEmpty);
        expect(find.text('Belum ada aktivitas'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'redesigned account page marks email read-only as Terverifikasi',
      (tester) async {
        final profile = ProfileData();
        await tester.pumpWidget(
          ChangeNotifierProvider<ProfileData>.value(
            value: profile,
            child: MaterialApp(
              theme: SkinTokens.theme(),
              home: const SkinAccountPage(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Terverifikasi'), findsOneWidget);
        expect(find.byKey(const Key('edit-profile-email')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
