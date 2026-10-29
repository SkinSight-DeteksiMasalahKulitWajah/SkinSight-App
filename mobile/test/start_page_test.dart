import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinsight/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final size in const [Size(320, 568), Size(390, 844), Size(430, 932)]) {
    testWidgets('start page is responsive at ${size.width}px', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const SkinSightApp());
      await tester.pumpAndSettle();

      expect(find.text('Glow On the Go'), findsOneWidget);
      expect(find.textContaining('Start your'), findsOneWidget);
      expect(find.textContaining('skin journey'), findsOneWidget);
      expect(find.textContaining('Kenali kondisi kulitmu'), findsOneWidget);
      expect(find.text('Enter'), findsOneWidget);
      expect(find.byKey(const Key('start-button')), findsOneWidget);
      expect(find.byKey(const Key('start-login-link')), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.byKey(const Key('start-button')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Mulai opens the auth choice page', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const SkinSightApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start-button')));
    await tester.pumpAndSettle();

    expect(find.text('Mulai bersama SkinSight'), findsOneWidget);
    expect(find.byKey(const Key('auth-google')), findsOneWidget);
    expect(find.byKey(const Key('auth-email')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
