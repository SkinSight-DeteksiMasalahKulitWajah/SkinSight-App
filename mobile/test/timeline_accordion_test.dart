import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinsight/features/journeys/data/skin_journey_store.dart';
import 'package:skinsight/features/progress/domain/skin_timeline_engine.dart';
import 'package:skinsight/features/progress/presentation/skin_progress_page.dart';

void main() {
  testWidgets('kondisi di timeline tertutup lalu terbuka saat diketuk',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final store = SkinJourneyStore.instance..resetForTesting();
    store.saveQuestionnaire(
      {for (var i = 1; i <= 7; i++) 'M0$i': 'Tidak'},
      photoConsent: true,
    );
    store.addPhoto(
      Uint8List.fromList(List<int>.filled(64, 200)),
      visualFindings: const ['Acne'],
      modelConnected: true,
      detectionCounts: const {'Acne': 6},
      modelVersion: 'test-1',
      quality: 'pass',
    );
    store.baselineDate = SkinJourneyStore.day(store.today);

    // Isi kartu kondisi yang diharapkan muncul di timeline untuk Acne.
    final acne = SkinTimelineEngine(store).content('Acne', 0);

    await tester.pumpWidget(const MaterialApp(home: SkinProgressPage()));
    await tester.pumpAndSettle();

    // Timeline berada jauh di bawah; gulir sampai kartu kondisi terbangun.
    await tester.scrollUntilVisible(
      find.byKey(Key('timeline-class-'
          '${SkinJourneyStore.day(store.today).toIso8601String()}-Acne')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    final header = find.byKey(Key('timeline-class-'
        '${SkinJourneyStore.day(store.today).toIso8601String()}-Acne'));
    await tester.ensureVisible(header);
    await tester.pumpAndSettle();
    // Teks yang sama bisa muncul di bagian lain halaman: periksa di dalam accordion.
    final body = find.descendant(of: header, matching: find.text(acne.message));
    expect(body, findsNothing);

    await tester.tap(find.descendant(of: header, matching: find.text('Acne')));
    await tester.pumpAndSettle();
    expect(body, findsOneWidget);

    await tester.tap(find.descendant(of: header, matching: find.text('Acne')));
    await tester.pumpAndSettle();
    expect(body, findsNothing);
    expect(tester.takeException(), isNull);
  });
}
