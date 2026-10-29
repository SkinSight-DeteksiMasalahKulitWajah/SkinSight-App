import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinsight/data/skin_journey_store.dart';
import 'package:skinsight/main.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home shows only three newest logical activities',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final store = SkinJourneyStore.instance;
    store.photos.clear();
    store.pendingPhotos.clear();
    store.checkins.clear();
    store.baselineDate = null;
    addTearDown(() {
      store.photos.clear();
      store.pendingPhotos.clear();
      store.checkins.clear();
      store.baselineDate = null;
      store.setTestingDate(null);
    });

    for (final date in [
      DateTime(2026, 10, 10),
      DateTime(2026, 10, 12),
      DateTime(2026, 10, 13),
      DateTime(2026, 10, 14),
    ]) {
      store.setTestingDate(date);
      store.addPhoto(
        Uint8List.fromList(const [1, 2, 3]),
        visualFindings: const ['Acne'],
        skinType: 'Combination',
        quality: 'pass',
      );
    }

    // Foto terbaru merupakan bagian dari check-in sehingga tidak ditampilkan
    // lagi sebagai aktivitas scan terpisah.
    store.checkins.add(JourneyCheckin(
      date: DateTime(2026, 10, 15, 9, 30),
      dueDate: DateTime(2026, 10, 15),
      perClass: const {'Acne': 'Lebih baik'},
      treatment: 'Rutinitas biasa',
      irritation: 'Tidak ada',
      photoIds: [store.photos.first.id],
    ));
    store.setTestingDate(DateTime(2026, 10, 15, 10));

    await tester.pumpWidget(const SkinSightApp());
    await tester.pumpAndSettle();
    await enterHome(tester);

    await tester.scrollUntilVisible(
      find.text('Aktivitas Terbaru'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Aktivitas Terbaru'), findsOneWidget);
    expect(find.byKey(const Key('recent-activity-list')), findsOneWidget);
    final activityList = tester.widget<ListView>(
      find.byKey(const Key('recent-activity-list')),
    );
    final delegate =
        activityList.childrenDelegate as SliverChildBuilderDelegate;
    // ListView.separated juga menghitung dua separator sebagai child.
    expect((delegate.childCount! + 1) ~/ 2, 3);
    expect(find.text('Check-in selesai'), findsOneWidget);
    expect(find.text('Hasil scan tersimpan'), findsWidgets);
    expect(find.text('Scan awal tersimpan'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
