import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinsight/main.dart';
import 'package:skinsight/models/auth_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('email registration opens three-slide onboarding',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const SkinSightApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start-button')));
    await tester.pumpAndSettle();
    final emailChoice = find.byKey(const Key('auth-email'));
    await tester.ensureVisible(emailChoice);
    await tester.pumpAndSettle();
    await tester.tap(emailChoice);
    await tester.pumpAndSettle();

    expect(find.text('Buat akun SkinSight'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('register-name')),
      'Pengguna Baru',
    );
    await tester.enterText(
      find.byKey(const Key('login-email')),
      'pengguna.baru@skinsight.id',
    );
    await tester.ensureVisible(find.byKey(const Key('login-submit')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('onboarding-page')), findsOneWidget);
    expect(find.text('Kenali kondisi kulitmu'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    expect(find.text('Pantau perjalanan kulitmu'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    expect(find.text('Check-in rutin lebih mudah'), findsOneWidget);
    expect(find.text('Mulai'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    expect(find.text('Aktivitas Terbaru'), findsOneWidget);
    expect(AuthSession.instance.hasCompletedOnboarding, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ordinary login goes directly to home without onboarding',
      (tester) async {
    AuthSession.instance.completeOnboarding();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const SkinSightApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('auth-login')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('login-submit')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Aktivitas Terbaru'), findsOneWidget);
    expect(find.byKey(const Key('onboarding-page')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('auth choice and onboarding fit a compact phone', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const SkinSightApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start-button')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final compactEmailChoice = find.byKey(const Key('auth-email'));
    await tester.ensureVisible(compactEmailChoice);
    await tester.pumpAndSettle();
    await tester.tap(compactEmailChoice);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('register-name')),
      'Pengguna Baru',
    );
    await tester.enterText(
      find.byKey(const Key('login-email')),
      'compact.user@skinsight.id',
    );
    final submit = find.byKey(const Key('login-submit'));
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();

    for (var page = 0; page < 3; page++) {
      expect(tester.takeException(), isNull);
      if (page < 2) {
        await tester.tap(find.byKey(const Key('onboarding-next')));
        await tester.pumpAndSettle();
      }
    }
  });

  testWidgets('active persisted session starts at home', (tester) async {
    AuthSession.instance.signIn();

    await tester.pumpWidget(
      const SkinSightApp(respectPersistedSession: true),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aktivitas Terbaru'), findsOneWidget);
    expect(find.byKey(const Key('start-button')), findsNothing);
    expect(tester.takeException(), isNull);

    AuthSession.instance.signOut();
  });
}
