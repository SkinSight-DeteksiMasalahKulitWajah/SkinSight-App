import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinsight/data/skin_journey_store.dart';
import 'package:skinsight/features/progress/domain/skin_timeline_policy.dart';
import 'package:skinsight/features/progress/domain/skin_timeline_engine.dart';

void main() {
  group('Unified YOLO Detection Count Logic Tests', () {
    test('SkinJourneyStore registers all 5 conditions as detection classes', () {
      expect(SkinJourneyStore.detectionClasses, containsAll([
        'Acne',
        'PIH',
        'Dark Circle',
        'Redness',
        'Wrinkle',
      ]));
      expect(SkinJourneyStore.segmentationClasses, isEmpty);
    });

    test('SkinTimelinePolicy uses count metric for all 5 conditions', () {
      final classes = SkinTimelinePolicy.data['classes'] as Map<String, dynamic>;
      final classKeys = ['acne', 'pih', 'dark_circle', 'redness', 'wrinkle'];
      for (final key in classKeys) {
        final c = classes[key] as Map<String, dynamic>;
        expect(c['metric'], equals('count'), reason: '$key should use count metric');
      }
    });

    test('Redness policy bands operate on integer counts', () {
      final classes = SkinTimelinePolicy.data['classes'] as Map<String, dynamic>;
      final redness = classes['redness'] as Map<String, dynamic>;
      final bands = (redness['bands'] as List<dynamic>).cast<Map<String, dynamic>>();

      final low = bands.firstWhere((b) => b['code'] == 'R_LOW');
      expect(low['min'], equals(1));
      expect(low['max'], equals(4));

      final mid = bands.firstWhere((b) => b['code'] == 'R_MID');
      expect(mid['min'], equals(5));
      expect(mid['max'], equals(9));

      final high = bands.firstWhere((b) => b['code'] == 'R_HIGH');
      expect(high['min'], equals(10));
      expect(high['max'], isNull);
    });

    test('Wrinkle policy bands operate on integer counts', () {
      final classes = SkinTimelinePolicy.data['classes'] as Map<String, dynamic>;
      final wrinkle = classes['wrinkle'] as Map<String, dynamic>;
      final bands = (wrinkle['bands'] as List<dynamic>).cast<Map<String, dynamic>>();

      final low = bands.firstWhere((b) => b['code'] == 'W_LOW');
      expect(low['min'], equals(1));
      expect(low['max'], equals(3));

      final mid = bands.firstWhere((b) => b['code'] == 'W_MID');
      expect(mid['min'], equals(4));
      expect(mid['max'], equals(7));

      final high = bands.firstWhere((b) => b['code'] == 'W_HIGH');
      expect(high['min'], equals(8));
      expect(high['max'], isNull);
    });

    test('SkinJourneyStore records and aggregates count-based photo findings', () {
      final store = SkinJourneyStore.instance;
      store.resetForTesting();
      store.beginNewJourney(name: 'Test Journey Count');

      store.addPhoto(
        Uint8List.fromList([1, 2, 3]),
        visualFindings: const ['Redness', 'Wrinkle', 'Acne'],
        detectionCounts: const {
          'Redness': 3,
          'Wrinkle': 2,
          'Acne': 4,
          'PIH': 0,
          'Dark Circle': 1,
        },
        modelConnected: true,
        quality: 'pass',
        modelVersion: 'yolo11n-unified',
      );

      final historyRedness = store.metricHistory('Redness');
      expect(historyRedness, isNotEmpty);
      expect(historyRedness.first.value, equals(3.0));

      final historyWrinkle = store.metricHistory('Wrinkle');
      expect(historyWrinkle, isNotEmpty);
      expect(historyWrinkle.first.value, equals(2.0));
    });

    test('SkinTimelineEngine computes timeline state cleanly with counts', () {
      final store = SkinJourneyStore.instance;
      store.resetForTesting();
      store.beginNewJourney(name: 'Engine Test');
      store.setTestingDate(DateTime(2026, 10, 1));

      store.addPhoto(
        Uint8List.fromList([1, 2, 3]),
        visualFindings: const ['Redness', 'Wrinkle'],
        detectionCounts: const {'Redness': 6, 'Wrinkle': 5},
        modelConnected: true,
        quality: 'pass',
        modelVersion: 'yolo11n-unified',
      );

      final engine = SkinTimelineEngine(store);
      expect(engine.hasActiveTracks, isTrue);

      final rednessTrack = engine.tracks['Redness'];
      expect(rednessTrack, isNotNull);
      expect(rednessTrack!.firstValue, equals(6.0));
      expect(rednessTrack.band['code'], equals('R_MID'));

      final wrinkleTrack = engine.tracks['Wrinkle'];
      expect(wrinkleTrack, isNotNull);
      expect(wrinkleTrack!.firstValue, equals(5.0));
      expect(wrinkleTrack.band['code'], equals('W_MID'));
    });
  });
}
