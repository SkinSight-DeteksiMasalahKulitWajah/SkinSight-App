import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinsight/main.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final size in const [Size(320, 568), Size(390, 844)]) {
    testWidgets('profile page is responsive at ${size.width}px',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const SkinSightApp());
      await tester.pumpAndSettle();
      await enterHome(tester);

      expect(find.byKey(const Key('home-default-avatar')), findsOneWidget);
      expect(find.byKey(const Key('home-skin-girl')), findsOneWidget);
      expect(find.byKey(const Key('home-journey-cat')), findsOneWidget);
      await tester.tap(find.byKey(const Key('open-profile')));
      await tester.pumpAndSettle();

      // Kartu 1: identitas + akses "Profil Saya"; kartu 2: lainnya.
      expect(find.text('Profil Saya'), findsOneWidget);
      expect(find.text('Alea Kucing'), findsOneWidget);
      expect(find.byKey(const Key('open-account-details')), findsOneWidget);
      expect(find.byKey(const Key('logout-account')), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Halaman detail akun berisi semua informasi.
      await tester.tap(find.byKey(const Key('open-account-details')));
      await tester.pumpAndSettle();
      expect(find.text('Alea Kucing'), findsNWidgets(2));
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('••••••••••••'), findsOneWidget);
      expect(find.text('+62 812-3456-7890'), findsOneWidget);
      expect(find.text('alea.kucing@email.com'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('edited name is reflected on profile and home', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const SkinSightApp());
    await tester.pumpAndSettle();
    await enterHome(tester);
    await tester.tap(find.byKey(const Key('open-profile')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-account-details')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit-profile-name')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('profile-edit-input')),
      'Alea Putri',
    );
    await tester.tap(find.byKey(const Key('save-profile-edit')));
    await tester.pumpAndSettle();

    expect(find.text('Alea Putri'), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('account-back')));
    await tester.pumpAndSettle();
    expect(find.text('Alea Putri'), findsOneWidget);

    await tester.tap(find.byKey(const Key('profile-back')));
    await tester.pumpAndSettle();
    expect(find.text('Alea Putri'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('password editor validates and saves securely', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const SkinSightApp());
    await tester.pumpAndSettle();
    await enterHome(tester);
    await tester.tap(find.byKey(const Key('open-profile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-account-details')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit-profile-password')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('new-password-input')),
      'password-baru',
    );
    await tester.enterText(
      find.byKey(const Key('confirm-password-input')),
      'password-baru',
    );
    await tester.tap(find.byKey(const Key('save-password')));
    await tester.pumpAndSettle();

    expect(find.text('Password berhasil diperbarui.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
