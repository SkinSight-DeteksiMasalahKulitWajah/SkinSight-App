import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinsight/main.dart';
import 'package:skinsight/models/font_settings.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('settings changes global font and defaults to Plus Jakarta Sans',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    SkinFontSettings.instance.select(SkinFontChoice.roboto);
    addTearDown(
      () => SkinFontSettings.instance.select(SkinFontChoice.roboto),
    );

    await tester.pumpWidget(const SkinSightApp());
    await tester.pumpAndSettle();
    await enterHome(tester);

    expect(find.byKey(const Key('open-settings')), findsOneWidget);
    expect(SkinFontSettings.instance.fontFamily, 'PlusJakartaSans');

    await tester.tap(find.byKey(const Key('open-settings')));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.byKey(const Key('font-handwritten')));
    await tester.pumpAndSettle();
    expect(SkinFontSettings.instance.fontFamily, 'Kalam');

    await tester.tap(find.byKey(const Key('font-roboto')));
    await tester.pumpAndSettle();
    expect(SkinFontSettings.instance.fontFamily, 'PlusJakartaSans');
    expect(tester.takeException(), isNull);
  });

  testWidgets('start page uses the app body font', (tester) async {
    SkinFontSettings.instance.select(SkinFontChoice.roboto);
    addTearDown(
      () => SkinFontSettings.instance.select(SkinFontChoice.roboto),
    );

    await tester.pumpWidget(const SkinSightApp());
    await tester.pumpAndSettle();

    final startButton = find.byKey(const Key('start-button'));
    expect(startButton, findsOneWidget);
    expect(
      Theme.of(tester.element(startButton)).textTheme.bodyMedium?.fontFamily,
      'PlusJakartaSans',
    );
    expect(tester.takeException(), isNull);
  });
}
