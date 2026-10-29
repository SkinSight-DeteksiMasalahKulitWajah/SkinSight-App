import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinsight/theme/skin_theme.dart';
import 'package:skinsight/widgets/slide_to_start_button.dart';

void main() {
  Future<int Function()> pumpButton(WidgetTester tester) async {
    var started = 0;
    await tester.pumpWidget(MaterialApp(
      theme: SkinTokens.theme(),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 340,
            child: SlideToStartButton(
              key: const Key('cta'),
              label: 'Mulai',
              onStart: () => started++,
            ),
          ),
        ),
      ),
    ));
    return () => started;
  }

  testWidgets('ketuk menjalankan onStart satu kali', (tester) async {
    final started = await pumpButton(tester);
    await tester.tap(find.byKey(const Key('cta')));
    await tester.pumpAndSettle();
    expect(started(), 1);
  });

  testWidgets('geser sampai ujung menjalankan onStart', (tester) async {
    final started = await pumpButton(tester);
    await tester.drag(find.text('Mulai'), const Offset(320, 0));
    await tester.pumpAndSettle();
    expect(started(), 1);
  });

  testWidgets('geseran pendek kembali ke awal tanpa memulai', (tester) async {
    final started = await pumpButton(tester);
    final before = tester.getTopLeft(find.text('Mulai'));
    await tester.drag(find.text('Mulai'), const Offset(40, 0));
    await tester.pumpAndSettle();
    expect(started(), 0);
    expect(tester.getTopLeft(find.text('Mulai')), before);
  });

  testWidgets('Enter saat fokus menjalankan onStart (keyboard/web)',
      (tester) async {
    final started = await pumpButton(tester);
    // Tab memindahkan fokus ke tombol, seperti pengguna keyboard di web.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(started(), 1);
  });

  testWidgets('punya semantik tombol dengan petunjuk geser', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpButton(tester);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Mulai')),
      matchesSemantics(
        isButton: true,
        label: 'Mulai',
        hint: 'Geser ke kanan atau ketuk untuk memulai',
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });
}
