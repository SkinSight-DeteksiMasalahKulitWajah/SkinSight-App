import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinsight/main.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Try Now opens the interactive skin quiz', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const SkinSightApp());
    await tester.pumpAndSettle();
    await enterHome(tester);
    await tester.tap(find.byKey(const Key('open-quiz-try')));
    await tester.pumpAndSettle();

    expect(find.text('Kuis Kondisi Kulit'), findsOneWidget);
    expect(find.text('1 / 5'), findsOneWidget);
    expect(find.text('Berminyak di T-Zone'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Mengilap di seluruh wajah'));
    await tester.ensureVisible(find.byKey(const Key('quiz-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quiz-continue')));
    await tester.pumpAndSettle();

    expect(find.text('2 / 5'), findsOneWidget);
    expect(
        find.text('Seberapa sering kulitmu terasa sensitif?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom scan button opens the quiz on a narrow phone', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const SkinSightApp());
    await tester.pumpAndSettle();
    await enterHome(tester);
    await tester.tap(find.byKey(const Key('open-quiz-scan')));
    await tester.pumpAndSettle();

    expect(find.text('Kuis Kondisi Kulit'), findsOneWidget);
    expect(find.byKey(const Key('quiz-continue')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
