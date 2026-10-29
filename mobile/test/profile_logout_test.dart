import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinsight/main.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('logout kembali ke halaman login', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const SkinSightApp());
    await tester.pumpAndSettle();
    await enterHome(tester);
    await tester.tap(find.byKey(const Key('open-profile')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('open-account-details')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('logout-account')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('logout-account')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-logout')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Selamat datang kembali'), findsOneWidget);
  });
}
