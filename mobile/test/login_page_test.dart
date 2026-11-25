import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:skinsight/core/theme/skin_theme.dart';
import 'package:skinsight/features/auth/data/auth_service.dart';
import 'package:skinsight/features/auth/models/auth_session.dart';
import 'package:skinsight/features/auth/presentation/skin_login_page.dart';
import 'package:skinsight/features/profile/models/profile_data.dart';
import 'package:skinsight/main.dart';

bool _fontsLoaded = false;

Future<void> _ensureAppFontsLoaded() async {
  if (_fontsLoaded) return;
  final loader = FontLoader('PlusJakartaSans');
  for (final path in const [
    'assets/fonts/PlusJakartaSans-Light.ttf',
    'assets/fonts/PlusJakartaSans-Regular.ttf',
    'assets/fonts/PlusJakartaSans-Medium.ttf',
    'assets/fonts/PlusJakartaSans-SemiBold.ttf',
    'assets/fonts/PlusJakartaSans-Bold.ttf',
    'assets/fonts/PlusJakartaSans-ExtraBold.ttf',
  ]) {
    final file = File(path);
    if (file.existsSync()) {
      final bytes = file.readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
  }
  await loader.load();
  _fontsLoaded = true;
}

Widget _buildDirectLoginApp() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ProfileData()),
      Provider<AuthService>(create: (_) => FakeAuthService()),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: SkinTokens.theme(),
      home: const SkinLoginPage(),
    ),
  );
}

Future<void> _openLogin(WidgetTester tester) async {
  await tester.pumpWidget(const SkinSightApp());
  await tester.pumpAndSettle();
  final startButton = find.byKey(const Key('start-button'));
  await tester.ensureVisible(startButton);
  await tester.pumpAndSettle();
  await tester.tap(startButton);
  await tester.pumpAndSettle();
  final loginChoice = find.byKey(const Key('auth-login'));
  if (loginChoice.evaluate().isNotEmpty) {
    await tester.ensureVisible(loginChoice);
    await tester.tap(loginChoice);
    await tester.pumpAndSettle();
  }
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

    await tester.enterText(
      find.byKey(const Key('login-email')),
      'alea@skinsight.id',
    );
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'skinsight123',
    );
    await tester.pumpAndSettle();

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
    expect(find.byKey(const Key('login-google')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in const [Size(390, 844), Size(412, 915), Size(800, 1280)]) {
    testWidgets(
      'login block is horizontally and vertically centered at ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await _ensureAppFontsLoaded();
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_buildDirectLoginApp());
        await tester.pumpAndSettle();

        final blockRect =
            tester.getRect(find.byKey(const Key('login-auth-block')));
        final cardRect = tester.getRect(find.byKey(const Key('login-card')));
        final expectedCenterX = size.width / 2;
        final expectedCenterY = size.height / 2;

        // Horizontal: blok & kartu tepat di tengah layar.
        expect(blockRect.center.dx, closeTo(expectedCenterX, 1.0));
        expect(cardRect.center.dx, closeTo(expectedCenterX, 1.0));
        // Vertikal: seluruh blok auth tepat di tengah viewport.
        expect(blockRect.center.dy, closeTo(expectedCenterY, 2.0));
        // Kartu duduk seimbang di pusat optik (sedikit di bawah brand anchor).
        expect(cardRect.center.dy, closeTo(expectedCenterY, 36.0));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('empty submit shows validation errors and password toggle works',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await _openLogin(tester);

    // Validasi belum muncul sebelum interaksi submit.
    expect(find.text('Email perlu diisi.'), findsNothing);
    expect(find.text('Password minimal 6 karakter.'), findsNothing);

    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Email perlu diisi.'), findsOneWidget);
    expect(find.text('Password minimal 6 karakter.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('login-password-visibility')));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Sembunyikan password'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in const [
    Size(320, 568),
    Size(360, 640),
    Size(740, 360),
    Size(800, 1280),
  ]) {
    testWidgets(
      'login and register modes have no overflow at ${size.width.toInt()}x${size.height.toInt()} with 1.3x text',
      (tester) async {
        await _ensureAppFontsLoaded();
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.pumpWidget(_buildDirectLoginApp());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final toggle = find.byKey(const Key('login-register-toggle'));
        await tester.ensureVisible(toggle);
        await tester.pumpAndSettle();
        await tester.tap(toggle);
        await tester.pumpAndSettle();

        expect(find.text('Buat akun SkinSight'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
