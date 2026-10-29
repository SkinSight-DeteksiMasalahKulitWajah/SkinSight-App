import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinsight/main.dart';

Future<void> _openLogin(WidgetTester tester) async {
  await tester.pumpWidget(const SkinSightApp());
  await tester.pumpAndSettle();
  final startButton = find.byKey(const Key('start-button'));
  await tester.ensureVisible(startButton);
  await tester.pumpAndSettle();
  await tester.tap(startButton);
  await tester.pumpAndSettle();
  final loginChoice = find.byKey(const Key('auth-login'));
  await tester.ensureVisible(loginChoice);
  await tester.tap(loginChoice);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('password salah tidak bisa masuk', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await _openLogin(tester);
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'password-salah',
    );
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Selamat datang kembali'), findsOneWidget);
    expect(find.text('Email atau password salah.'), findsOneWidget);
  });
}
