import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinsight/data/skin_journey_store.dart';
import 'package:skinsight/pages/skin_initial_scan_page.dart';
import 'package:skinsight/pages/skin_quiz_page.dart';
import 'package:skinsight/theme/skin_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final size in const [Size(320, 568), Size(390, 844)]) {
    testWidgets('initial scan collection is responsive at ${size.width}px',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: SkinTokens.theme(),
          home: const SkinInitialScanPage(enableCamera: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kumpulan Foto'), findsOneWidget);
      expect(find.byKey(const Key('initial-scan-empty')), findsOneWidget);
      expect(find.byKey(const Key('add-initial-scan')), findsOneWidget);
      expect(find.text('Foto'), findsNothing);
      expect(find.text('Output'), findsNothing);
      expect(find.text('Lihat rata-rata hasil'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('save-initial-scans')),
            )
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('completed questionnaire opens initial scan collection',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final store = SkinJourneyStore.instance;
    store.answers.clear();
    store.consent = null;
    store.saveQuestionnaire(
      const {
        'M01': 'Tidak',
        'M02': 'Tidak memakai',
        'M03': 'Tidak',
        'M04': 'Tidak',
        'M05': 'Kadang',
        'M06': 'Tidak',
        'M07': 'Acne|Redness',
      },
      photoConsent: true,
    );
    addTearDown(() {
      store.answers.clear();
      store.consent = null;
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: SkinTokens.theme(),
        home: const SkinQuizPage(enableCamera: false),
      ),
    );
    await tester.pumpAndSettle();

    final continueButton = find.text('Lanjut ke Scan');
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.text('Scan Wajah'), findsOneWidget);
    expect(find.byKey(const Key('capture-selfie')), findsOneWidget);
    await tester.tap(find.byKey(const Key('scan-back')));
    await tester.pumpAndSettle();
    expect(find.text('Kumpulan Foto'), findsOneWidget);
    expect(find.text('Tambah Foto'), findsOneWidget);
    expect(find.text('Belum ada foto baseline'), findsOneWidget);
    expect(find.text('Buat baseline yang lebih konsisten'), findsNothing);
    expect(
      find.text(
        'Ambil hingga 3 foto dengan cahaya dan posisi wajah yang sama. Kamu tetap bisa menyimpan setelah 1 foto.',
      ),
      findsNothing,
    );
    expect(
      find.text(
        'Mulai dari foto tampak depan dengan pencahayaan merata.',
      ),
      findsNothing,
    );
    expect(find.byKey(const Key('start-initial-scan')), findsNothing);
    await tester.tap(find.byKey(const Key('initial-scan-back')));
    await tester.pumpAndSettle();
    expect(find.text('Kuesioner Awal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('three scans are averaged and saved as one baseline',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final store = SkinJourneyStore.instance;
    store.resetForTesting();
    store.beginNewJourney();
    store.photos.clear();
    store.pendingPhotos.clear();
    store.checkins.clear();
    store.closedConditions.clear();
    store.baselineDate = null;
    store.consent = true;
    addTearDown(() {
      store.photos.clear();
      store.pendingPhotos.clear();
      store.checkins.clear();
      store.closedConditions.clear();
      store.baselineDate = null;
      store.consent = null;
    });

    final imageBytes = Uint8List.fromList(base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    ));

    await tester.pumpWidget(
      MaterialApp(
        theme: SkinTokens.theme(),
        home: SkinInitialScanPage(
          enableCamera: false,
          capturePhoto: (_) async => imageBytes,
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var index = 1; index <= 3; index++) {
      await tester.tap(find.byKey(const Key('add-initial-scan')));
      await tester.pumpAndSettle();
      expect(find.text('Hasil Analisis'), findsOneWidget);
      expect(find.text('Kembali ke Foto'), findsNothing);
      expect(find.byKey(const Key('review-retry-scan')), findsOneWidget);
      expect(find.byKey(const Key('review-save-photo')), findsOneWidget);
      expect(find.byKey(const Key('save-result')), findsNothing);
      expect(store.photos, isEmpty);
      if (index == 3) {
        await tester.scrollUntilVisible(
          find.byKey(const Key('result-compact-findings-v10')),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(
          find.byKey(const Key('result-compact-findings-v10')),
          findsOneWidget,
        );
      }
      await tester.tap(find.byKey(const Key('review-save-photo')));
      await tester.pumpAndSettle();
      expect(find.text('Kumpulan Foto'), findsOneWidget);
    }

    expect(find.byKey(const Key('initial-scan-1')), findsOneWidget);
    expect(find.byKey(const Key('initial-scan-2')), findsOneWidget);
    expect(find.byKey(const Key('initial-scan-3')), findsOneWidget);
    expect(find.byKey(const Key('initial-average-result')), findsOneWidget);
    expect(find.text('Rata-rata Hasil'), findsOneWidget);
    expect(find.text('3 foto'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('initial-average-Acne')),
        matching: find.text('5'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('open-initial-scan-1')));
    await tester.pumpAndSettle();
    expect(find.text('Hasil Analisis'), findsOneWidget);
    expect(find.byKey(const Key('review-save-photo')), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const Key('result-finding-Acne')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('result-finding-Acne')),
        matching: find.text('4'),
      ),
      findsOneWidget,
    );
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const Key('add-initial-scan')),
          )
          .onPressed,
      isNull,
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('remove-initial-scan-2')),
      -180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('remove-initial-scan-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('initial-scan-3')), findsNothing);

    await tester.scrollUntilVisible(
      find.byKey(const Key('add-initial-scan')),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('2/3'), findsOneWidget);
    await tester.tap(find.byKey(const Key('add-initial-scan')));
    await tester.pumpAndSettle();
    expect(find.text('Hasil Analisis'), findsOneWidget);
    await tester.tap(find.byKey(const Key('review-save-photo')));
    await tester.pumpAndSettle();
    expect(find.text('3/3'), findsOneWidget);

    await tester.tap(find.byKey(const Key('save-initial-scans')));
    await tester.pumpAndSettle();

    expect(find.text('Beri nama perjalanan'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('new-journey-name-field')),
      'Journey Acne Oktober',
    );
    await tester.tap(find.byKey(const Key('confirm-new-journey-name')));
    await tester.pumpAndSettle();

    expect(store.photos, hasLength(1));
    expect(store.baselineDate, isNotNull);
    expect(store.photos.single.detectionCounts['Acne'], 5);
    expect(store.selectedJourneyName, 'Journey Acne Oktober');
    expect(store.journeys, hasLength(1));
    expect(tester.takeException(), isNull);
  });
}
