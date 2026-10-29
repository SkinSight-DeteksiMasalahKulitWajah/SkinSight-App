import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinsight/data/skin_journey_store.dart';
import 'package:skinsight/pages/skin_journeys_page.dart';

void main() {
  final store = SkinJourneyStore.instance;

  setUp(store.resetForTesting);
  tearDown(store.resetForTesting);

  Future<void> pumpPage(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(home: SkinJourneysPage()),
    );
    await tester.pumpAndSettle();
  }

  test('each journey keeps its own timeline data', () {
    final first = store.beginNewJourney(name: 'Journey Pertama');
    store.saveQuestionnaire(const {'M01': 'Tidak'}, photoConsent: true);
    store.setTestingDate(DateTime(2026, 10, 1));
    store.addPhoto(
      Uint8List.fromList([1, 2, 3]),
      visualFindings: const ['Acne'],
      isDemo: true,
      modelConnected: true,
      detectionCounts: const {'Acne': 3},
      modelVersion: 'test-model',
      quality: 'pass',
    );
    final firstBaseline = store.baselineDate;
    store.checkins.add(JourneyCheckin(
      date: DateTime(2026, 10, 22),
      dueDate: DateTime(2026, 10, 22),
      perClass: const {'Acne': 'Membaik'},
      treatment: 'Basic skincare',
      irritation: 'Tidak',
      photoIds: [store.photos.single.id],
    ));
    expect(store.journeys, isEmpty);
    store.finalizeCurrentJourney('Journey Pertama');

    final second = store.beginNewJourney(name: 'Journey Kedua');
    store.saveQuestionnaire(const {'M01': 'Ya'}, photoConsent: true);
    store.setTestingDate(DateTime(2026, 11, 1));
    store.addPhoto(
      Uint8List.fromList([4, 5, 6]),
      visualFindings: const ['Acne'],
      isDemo: true,
      modelConnected: true,
      detectionCounts: const {'Acne': 8},
      modelVersion: 'test-model',
      quality: 'pass',
    );
    final secondBaseline = store.baselineDate;
    store.finalizeCurrentJourney('Journey Kedua');
    expect(store.photos.single.detectionCounts['Acne'], 8);
    expect(store.checkins, isEmpty);
    expect(store.selectedJourneyName, 'Journey Kedua');

    expect(store.selectJourney(first.id), isTrue);
    expect(store.photos, hasLength(1));
    expect(store.photos.single.detectionCounts['Acne'], 3);
    expect(store.answers['M01'], 'Tidak');
    expect(store.baselineDate, firstBaseline);
    expect(store.checkins, hasLength(1));
    expect(store.metricHistory('Acne').single.value, 3);

    expect(store.selectJourney(second.id), isTrue);
    expect(store.photos.single.detectionCounts['Acne'], 8);
    expect(store.answers['M01'], 'Ya');
    expect(store.baselineDate, secondBaseline);
    expect(store.checkins, isEmpty);
    expect(store.metricHistory('Acne').single.value, 8);
  });

  test('demo completion closes the active journey timeline', () {
    store.beginNewJourney(name: 'Journey Demo Selesai');
    store.saveQuestionnaire(const {'M01': 'Tidak'}, photoConsent: true);
    store.setTestingDate(DateTime(2026, 10, 1));
    store.addPhoto(
      Uint8List.fromList([1, 2, 3]),
      visualFindings: const ['Acne'],
      isDemo: true,
      modelConnected: true,
      detectionCounts: const {'Acne': 3},
      modelVersion: 'test-model',
      quality: 'pass',
    );
    store.finalizeCurrentJourney('Journey Demo Selesai');

    expect(store.completeSelectedJourneyForDemo(), isTrue);
    expect(store.selectedJourneyStatus, JourneyStatus.completed);
    expect(store.closedConditions, contains('Acne'));
    expect(store.allTimelinesCompleted, isTrue);
    expect(store.shouldShowJourneyCompletion, isTrue);
  });

  testWidgets('new journey stays a draft while questionnaire is open',
      (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('start-new-journey')));
    await tester.pumpAndSettle();

    expect(find.text('Kuesioner Awal'), findsOneWidget);
    expect(store.journeys, isEmpty);
    expect(store.selectedJourney.isDraft, isTrue);
  });

  testWidgets('tapping a saved journey opens its own Skin Journey page',
      (tester) async {
    final journey = store.beginNewJourney(name: 'Journey PIH');
    store.finalizeCurrentJourney('Journey PIH');
    await pumpPage(tester);

    await tester.scrollUntilVisible(
      find.byKey(Key('journey-card-${journey.id}')),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(Key('journey-card-${journey.id}')));
    await tester.pumpAndSettle();

    expect(find.text('Journey PIH'), findsOneWidget);
    expect(find.text('Mulai perjalanan kulitmu'), findsOneWidget);
    expect(store.selectedJourney.id, journey.id);
  });

  for (final size in const [
    Size(320, 568),
    Size(390, 844),
    Size(430, 932),
  ]) {
    testWidgets('journey list is responsive at ${size.width.toInt()}px',
        (tester) async {
      store.beginNewJourney(name: 'Journey Responsif');
      store.finalizeCurrentJourney('Journey Responsif');
      await pumpPage(tester, size: size);

      expect(find.byKey(const Key('start-new-journey')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Journey Responsif'),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Journey Responsif'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('journey can be renamed, pinned, completed, and reactivated',
      (tester) async {
    final journey = store.beginNewJourney(name: 'Perjalanan Lama');
    store.finalizeCurrentJourney('Perjalanan Lama');
    await pumpPage(tester);

    expect(find.text('Perjalanan Lama'), findsOneWidget);
    expect(find.text('Aktif'), findsOneWidget);

    await tester.tap(find.byKey(Key('journey-menu-${journey.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('rename-journey-${journey.id}')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('journey-name-field')),
      'Journey Acne',
    );
    await tester.tap(find.byKey(const Key('save-journey-name')));
    await tester.pumpAndSettle();
    expect(find.text('Journey Acne'), findsOneWidget);

    await tester.tap(find.byKey(Key('journey-menu-${journey.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('pin-journey-${journey.id}')));
    await tester.pumpAndSettle();
    expect(journey.isPinned, isTrue);

    await tester.tap(find.byKey(Key('journey-menu-${journey.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tandai selesai'));
    await tester.pumpAndSettle();
    expect(find.text('Selesai'), findsOneWidget);

    await tester.tap(find.byKey(Key('journey-menu-${journey.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aktifkan kembali'));
    await tester.pumpAndSettle();
    expect(find.text('Aktif'), findsOneWidget);
  });

  testWidgets('cancelled journey moves to trash and can be restored',
      (tester) async {
    final journey = store.beginNewJourney(name: 'Journey Sensitif');
    store.finalizeCurrentJourney('Journey Sensitif');
    await pumpPage(tester);

    await tester.tap(find.byKey(Key('journey-menu-${journey.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('cancel-journey-${journey.id}')));
    await tester.pumpAndSettle();
    expect(find.text('Batal'), findsOneWidget);

    await tester.tap(find.byKey(Key('journey-menu-${journey.id}')));
    await tester.pumpAndSettle();
    final trashAction = find.byKey(Key('trash-journey-${journey.id}'));
    await tester.ensureVisible(trashAction);
    await tester.tap(trashAction);
    await tester.pumpAndSettle();

    expect(find.text('Journey Sensitif'), findsNothing);
    expect(store.trashedJourneys, contains(journey));

    await tester.tap(find.byKey(const Key('open-journey-trash')));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('trashed-journey-${journey.id}')), findsOneWidget);

    await tester.tap(find.byKey(Key('restore-journey-${journey.id}')));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('trashed-journey-${journey.id}')), findsNothing);

    await tester.tap(find.byKey(const Key('journey-trash-back')));
    await tester.pumpAndSettle();
    expect(find.text('Journey Sensitif'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
  });
}
