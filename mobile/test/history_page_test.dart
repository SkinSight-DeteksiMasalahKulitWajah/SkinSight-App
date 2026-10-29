import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinsight/data/skin_history_repository.dart';
import 'package:skinsight/main.dart';
import 'package:skinsight/pages/skin_history_page.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final size in const [Size(320, 568), Size(390, 844)]) {
    testWidgets('history page is responsive at ${size.width}px',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: SkinHistoryPage()));
      await tester.pumpAndSettle();

      expect(find.text('Riwayat Analisis'), findsOneWidget);
      expect(find.text('DAFTAR SCAN'), findsOneWidget);
      expect(find.text('Kombinasi (T-Zone)'), findsOneWidget);
      expect(find.text('Kemerahan ringan'), findsOneWidget);
      expect(find.text('Breakout dagu'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('home history card opens history page', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const SkinSightApp());
    await tester.pumpAndSettle();
    await enterHome(tester);
    final historyCard = find.byKey(const Key('open-history'));
    await tester.ensureVisible(historyCard);
    await tester.pumpAndSettle();
    await tester.tap(historyCard);
    await tester.pumpAndSettle();

    expect(find.text('Riwayat Analisis'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sort toggles from newest to oldest', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: SkinHistoryPage()));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Kombinasi (T-Zone)')).dy,
      lessThan(tester.getTopLeft(find.text('Breakout dagu')).dy),
    );

    await tester.tap(find.byKey(const Key('history-sort-toggle')));
    await tester.pumpAndSettle();

    expect(find.text('Terlama'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Breakout dagu')).dy,
      lessThan(tester.getTopLeft(find.text('Kombinasi (T-Zone)')).dy),
    );
  });

  testWidgets('date filter limits the visible scan list', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: SkinHistoryPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('history-filter-date')));
    await tester.pumpAndSettle();

    expect(find.text('Pilih tanggal scan'), findsOneWidget);
    await tester.tap(find.text('3').last);
    await tester.tap(find.text('Pilih'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('clear-history-filter')), findsOneWidget);
    expect(find.text('Kombinasi (T-Zone)'), findsOneWidget);
    expect(find.text('Kemerahan ringan'), findsNothing);
    expect(find.text('Breakout dagu'), findsNothing);
  });

  testWidgets('saved history detail reuses result page without save button',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: SkinHistoryPage()));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('history-detail-scan-2026-10-03')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hasil Diagnosis'), findsOneWidget);
    expect(find.text('Hasil scan tersimpan'), findsOneWidget);
    expect(find.byKey(const Key('save-result')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('dummy repository filters records by date', () async {
    final records = await SkinHistoryRepository.instance.fetchHistory(
      date: DateTime(2026, 9, 27),
    );

    expect(records, hasLength(1));
    expect(records.single.title, 'Kemerahan ringan');
  });
}
