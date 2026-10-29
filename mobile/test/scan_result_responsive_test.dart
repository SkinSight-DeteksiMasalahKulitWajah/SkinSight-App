import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinsight/pages/skin_quiz_page.dart';
import 'package:skinsight/pages/skin_result_page.dart';
import 'package:skinsight/pages/skin_scan_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final size in const [Size(320, 568), Size(390, 844)]) {
    testWidgets('scan page has no overflow at ${size.width}px', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(home: SkinScanPage(enableCamera: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Scan Wajah'), findsOneWidget);
      expect(find.byKey(const Key('capture-selfie')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('result page has no overflow at ${size.width}px', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: SkinResultPage()));
      await tester.pumpAndSettle();

      expect(find.text('Hasil Diagnosis'), findsOneWidget);
      expect(find.text('Selfie berhasil dianalisis'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Masalah Ditemukan'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Masalah Ditemukan'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('finishing question five opens the scan page', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: SkinQuizPage(enableCamera: false)),
    );
    await tester.pumpAndSettle();

    for (var question = 1; question <= 5; question++) {
      final continueButton = find.byKey(const Key('quiz-continue'));
      await tester.ensureVisible(continueButton);
      await tester.pumpAndSettle();
      await tester.tap(continueButton);
      await tester.pumpAndSettle();
    }

    expect(find.text('Scan Wajah'), findsOneWidget);
    expect(find.byKey(const Key('capture-selfie')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
