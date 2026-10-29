import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinsight/main.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const phoneSizes = <Size>[
    Size(320, 568),
    Size(375, 812),
    Size(390, 844),
    Size(430, 932),
  ];

  for (final size in phoneSizes) {
    testWidgets('home layout has no overflow at ${size.width.toInt()}px', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const SkinSightApp());
      await tester.pumpAndSettle();
      await enterHome(tester);

      expect(find.text('Aktivitas Terbaru'), findsOneWidget);
      expect(find.byKey(const Key('recent-activity-empty')), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home-open-skin-journey')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('home cannot be pulled below the top edge', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const SkinSightApp());
    await tester.pumpAndSettle();
    await enterHome(tester);

    final scrollView = tester.widget<CustomScrollView>(
      find.byType(CustomScrollView).first,
    );
    expect(scrollView.physics, isA<ClampingScrollPhysics>());

    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    final gesture = await tester.startGesture(const Offset(195, 220));
    await gesture.moveBy(const Offset(0, 280));
    await tester.pump();

    expect(scrollable.position.pixels, greaterThanOrEqualTo(0));
    await gesture.up();
  });
}
