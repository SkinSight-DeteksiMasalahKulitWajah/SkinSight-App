import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinsight/main.dart';

import 'test_helpers.dart';

Future<void> _openLogin(WidgetTester tester) async {
  await tester.pumpWidget(const SkinSightApp());
  await tester.pumpAndSettle();
  final start = find.byKey(const Key('start-login-link'));
  await tester.ensureVisible(start);
  await tester.tap(start);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login links open privacy and terms pages', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await _openLogin(tester);

    final privacyLink = find.byKey(const Key('login-open-privacy'));
    await tester.ensureVisible(privacyLink);
    await tester.tap(privacyLink);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('privacy-page')), findsOneWidget);
    expect(find.text('Kebijakan Privasi'), findsWidgets);
    expect(find.textContaining('Status dokumen: draf'), findsOneWidget);

    await tester.tap(find.byKey(const Key('legal-back')));
    await tester.pumpAndSettle();

    final termsLink = find.byKey(const Key('login-open-terms'));
    await tester.ensureVisible(termsLink);
    await tester.tap(termsLink);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('terms-page')), findsOneWidget);
    expect(find.text('Syarat & Ketentuan'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('about bubbles open both legal pages', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const SkinSightApp());
    await tester.pumpAndSettle();
    await enterHome(tester);
    await tester.tap(find.byKey(const Key('open-about')));
    await tester.pumpAndSettle();

    expect(find.text('Profil Kami'), findsOneWidget);
    await tester.tap(find.byKey(const Key('about-open-privacy')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('privacy-page')), findsOneWidget);
    await tester.tap(find.byKey(const Key('legal-back')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('about-open-terms')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('terms-page')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
