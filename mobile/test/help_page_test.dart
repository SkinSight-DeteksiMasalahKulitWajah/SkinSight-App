import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinsight/main.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final size in const [Size(320, 568), Size(390, 844)]) {
    testWidgets('help page is responsive at ${size.width}px', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const SkinSightApp());
      await tester.pumpAndSettle();
      await enterHome(tester);
      await tester.tap(find.byKey(const Key('bottom-profile')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('profile-open-help')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('profile-open-help')));
      await tester.pumpAndSettle();

      expect(find.text('Pusat Bantuan'), findsOneWidget);
      expect(find.text('Cara menggunakan SkinSight'), findsOneWidget);
      expect(find.text('FAQ'), findsOneWidget);
      expect(find.text('Hubungi kami'), findsOneWidget);
      expect(find.text('Kebijakan privasi'), findsOneWidget);
      expect(find.text('Tentang SkinSight'), findsOneWidget);
      expect(tester.takeException(), isNull);

      expect(find.text('Isi kuis kondisi kulit'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('help back button returns to the profile tab', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const SkinSightApp());
    await tester.pumpAndSettle();
    await enterHome(tester);
    await tester.tap(find.byKey(const Key('bottom-profile')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('profile-open-help')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-open-help')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('help-back')));
    await tester.pumpAndSettle();

    expect(find.text('Profil Saya'), findsOneWidget);
    expect(find.byKey(const Key('profile-open-help')), findsOneWidget);
    expect(find.byKey(const Key('profile-open-about')), findsOneWidget);
  });
}
