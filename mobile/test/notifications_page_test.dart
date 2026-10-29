import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinsight/data/skin_journey_store.dart';
import 'package:skinsight/data/skin_notification_center.dart';
import 'package:skinsight/main.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('notification bell opens logical feed without settings',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final store = SkinJourneyStore.instance;
    final center = SkinNotificationCenter.instance;
    store.photos.clear();
    store.pendingPhotos.clear();
    store.checkins.clear();
    store.baselineDate = null;
    center.reset();
    addTearDown(() {
      store.photos.clear();
      store.pendingPhotos.clear();
      store.checkins.clear();
      store.baselineDate = null;
      store.setTestingDate(null);
      center.reset();
    });

    await tester.pumpWidget(const SkinSightApp());
    await tester.pumpAndSettle();
    await enterHome(tester);

    expect(
        find.byKey(const Key('home-notification-unread-dot')), findsOneWidget);
    await tester.tap(find.byKey(const Key('open-notifications')));
    await tester.pumpAndSettle();

    expect(find.text('Notifikasi'), findsOneWidget);
    expect(find.text('Mulai scan awalmu'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsNothing);
    expect(find.byIcon(Icons.settings_rounded), findsNothing);

    await tester.tap(find.byKey(const Key('mark-all-notifications-read')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('notifications-back')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-notification-unread-dot')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('about page remains responsive at compact width', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const SkinSightApp());
    await tester.pumpAndSettle();
    await enterHome(tester);
    await tester.tap(find.byKey(const Key('bottom-profile')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('profile-open-about')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-open-about')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('about-hero')), findsOneWidget);
    expect(find.byKey(const Key('about-page-title')), findsOneWidget);
    expect(
      find.text('Membantu mencatat, bukan mendiagnosis.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
