import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinsight/data/skin_journey_store.dart';
import 'package:skinsight/pages/skin_quiz_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Lanjut ke Scan is disabled until photo consent is checked',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(() => SkinJourneyStore.instance.consent = null);

    SkinJourneyStore.instance.consent = false;

    await tester.pumpWidget(
      const MaterialApp(home: SkinQuizPage(enableCamera: false)),
    );
    await tester.pumpAndSettle();

    FilledButton continueButton() => tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Lanjut ke Scan'),
        );

    expect(continueButton().onPressed, isNull);

    final consentLabel = find.text(
      'Saya mengizinkan foto diproses untuk analisis dan pemantauan.',
    );
    await tester.ensureVisible(consentLabel);
    await tester.pumpAndSettle();
    await tester.tap(consentLabel);
    await tester.pumpAndSettle();

    expect(continueButton().onPressed, isNotNull);

    await tester.tap(consentLabel);
    await tester.pumpAndSettle();

    expect(continueButton().onPressed, isNull);
    expect(tester.takeException(), isNull);
  });
}
