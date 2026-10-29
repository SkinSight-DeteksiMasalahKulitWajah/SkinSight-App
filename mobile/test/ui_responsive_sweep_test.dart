import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinsight/main.dart';
import 'package:skinsight/models/auth_session.dart';

/// Sapuan responsif: setiap rute utama dibuka di berbagai ukuran layar
/// (HP kecil → tablet → desktop) dan skala teks sistem, lalu dipastikan tidak
/// ada error layout (overflow / constraint) yang terlempar.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sizes = <Size>[
    Size(320, 568), // iPhone SE (1st gen) / HP Android kecil
    Size(360, 640), // Android kecil umum
    Size(360, 800), // Android 20:9
    Size(390, 844), // iPhone 12–15
    Size(412, 915), // Pixel / Galaxy besar
    Size(430, 932), // iPhone Pro Max
    Size(600, 960), // tablet kecil (portrait)
    Size(800, 1280), // tablet
    Size(740, 360), // HP landscape
  ];

  const routes = <String>[
    '/',
    '/auth',
    '/login',
    '/register',
    '/onboarding',
    '/home',
    '/help',
    '/history',
    '/notifications',
    '/profile',
    '/account',
    '/settings',
    '/about',
    '/privacy',
    '/terms',
  ];

  for (final scale in const [1.0, 1.3]) {
    for (final size in sizes) {
      testWidgets(
          'semua halaman tanpa error layout di '
          '${size.width.toInt()}×${size.height.toInt()} (teks ×$scale)',
          (tester) async {
        tester.view.devicePixelRatio = 2;
        tester.view.physicalSize = size * 2;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        AuthSession.instance.completeOnboarding();

        await tester.pumpWidget(const SkinSightApp());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'rute /');

        final navigator =
            tester.state<NavigatorState>(find.byType(Navigator).first);
        for (final route in routes.skip(1)) {
          navigator.pushNamed(route);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'rute $route');

          // Gulir ke bawah untuk memeriksa konten di luar layar.
          final scrollables = find.byType(Scrollable);
          if (scrollables.evaluate().isNotEmpty) {
            await tester.drag(scrollables.first, const Offset(0, -600),
                warnIfMissed: false);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull,
                reason: 'rute $route (digulir)');
          }
          navigator.pop();
          await tester.pumpAndSettle();
        }
      });
    }
  }
}
