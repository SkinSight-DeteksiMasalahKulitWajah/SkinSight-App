import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinsight/main.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('bottom nav exposes Home, Edukasi, and Profil only',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const SkinSightApp());
    await tester.pumpAndSettle();
    await enterHome(tester);

    expect(find.byKey(const Key('bottom-home')), findsOneWidget);
    expect(find.byKey(const Key('open-education')), findsOneWidget);
    expect(find.byKey(const Key('bottom-profile')), findsOneWidget);
    expect(find.byKey(const Key('open-help')), findsNothing);
    expect(find.byKey(const Key('open-about')), findsNothing);

    await tester.tap(find.byKey(const Key('bottom-profile')));
    await tester.pumpAndSettle();

    expect(find.text('Profil Saya'), findsOneWidget);
    expect(find.byKey(const Key('profile-open-help')), findsOneWidget);
    expect(find.byKey(const Key('profile-open-about')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile opens help and about pages', (tester) async {
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
    expect(find.text('Pusat Bantuan'), findsOneWidget);

    await tester.tap(find.byKey(const Key('help-back')));
    await tester.pumpAndSettle();
    expect(find.text('Profil Saya'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('profile-open-about')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-open-about')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('about-page-title')), findsOneWidget);

    await tester.tap(find.byKey(const Key('about-back')));
    await tester.pumpAndSettle();
    expect(find.text('Profil Saya'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
