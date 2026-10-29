import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinsight/main.dart';
import 'package:skinsight/models/auth_session.dart';

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

  for (final size in const [Size(320, 568), Size(390, 844)]) {
    testWidgets('login page is responsive at ${size.width}px', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await _openLogin(tester);

      expect(find.text('Selamat datang kembali'), findsOneWidget);
      expect(find.byKey(const Key('login-email')), findsOneWidget);
      expect(find.byKey(const Key('login-password')), findsOneWidget);
      expect(find.text('Masuk dengan Google'), findsOneWidget);
      expect(find.text('Belum punya akun?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('dummy email and password can log in', (tester) async {
    AuthSession.instance.completeOnboarding();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await _openLogin(tester);

    final email = tester.widget<TextFormField>(
      find.byKey(const Key('login-email')),
    );
    final passwordField = find.byKey(const Key('login-password'));
    final password = tester.widget<TextFormField>(passwordField);
    final passwordEditor = tester.widget<EditableText>(
      find.descendant(of: passwordField, matching: find.byType(EditableText)),
    );
    expect(email.controller?.text, 'alea@skinsight.id');
    expect(password.controller?.text, 'skinsight123');
    expect(passwordEditor.obscureText, isTrue);

    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login-google')), findsNothing);
    expect(find.byKey(const Key('bottom-home')), findsOneWidget);
    expect(find.text('Aktivitas Terbaru'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Google login opens home', (tester) async {
    AuthSession.instance.completeOnboarding();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await _openLogin(tester);
    await tester.tap(find.byKey(const Key('login-google')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login-google')), findsNothing);
    expect(find.byKey(const Key('bottom-home')), findsOneWidget);
    expect(find.text('Aktivitas Terbaru'), findsOneWidget);
  });

  testWidgets('Daftar link opens the registration form', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await _openLogin(tester);
    final registerToggle = find.byKey(const Key('login-register-toggle'));
    await tester.ensureVisible(registerToggle);
    await tester.pumpAndSettle();
    await tester.tap(registerToggle);
    await tester.pumpAndSettle();

    expect(find.text('Buat akun SkinSight'), findsOneWidget);
    expect(find.byKey(const Key('register-name')), findsOneWidget);
    expect(find.text('Daftar'), findsOneWidget);
    expect(find.byKey(const Key('login-google')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
