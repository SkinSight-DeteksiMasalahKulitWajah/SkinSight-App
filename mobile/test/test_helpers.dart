import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinsight/models/auth_session.dart';

Future<void> enterHome(WidgetTester tester) async {
  AuthSession.instance.completeOnboarding();
  final startButton = find.byKey(const Key('start-button'));
  await tester.ensureVisible(startButton);
  await tester.pumpAndSettle();
  await tester.tap(startButton);
  await tester.pumpAndSettle();

  final authLogin = find.byKey(const Key('auth-login'));
  await tester.ensureVisible(authLogin);
  await tester.pumpAndSettle();
  await tester.tap(authLogin);
  await tester.pumpAndSettle();

  final googleButton = find.byKey(const Key('login-google'));
  await tester.ensureVisible(googleButton);
  await tester.pumpAndSettle();
  await tester.tap(googleButton);
  await tester.pumpAndSettle();
}
