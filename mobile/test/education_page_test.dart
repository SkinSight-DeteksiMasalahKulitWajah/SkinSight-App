import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinsight/pages/skin_education_page.dart';
import 'package:skinsight/theme/skin_theme.dart';

void main() {
  Widget buildPage() => MaterialApp(
        theme: SkinTokens.theme(),
        home: const SkinEducationPage(),
      );

  testWidgets('education page exposes editorial content and footer label',
      (tester) async {
    await tester.pumpWidget(buildPage());

    // Bilah navigasi kini berupa ikon (label ada di Semantics/Tooltip),
    // jadi teks "Edukasi" hanya muncul sebagai judul halaman.
    expect(find.text('Edukasi'), findsOneWidget);
    expect(find.bySemanticsLabel('Edukasi'), findsOneWidget);
    expect(find.textContaining('Kenali kulitmu'), findsNothing);
    expect(find.text('BACA SESUAI KEBUTUHAN'), findsNothing);
    expect(find.text('PILIHAN MINGGU INI'), findsNothing);
    expect(find.text('Mulai dari yang penting'), findsNothing);
    expect(find.text('Artikel rekomendasi'), findsOneWidget);
    expect(find.byKey(const Key('education-featured')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('topic filter and search narrow the reading list',
      (tester) async {
    await tester.pumpWidget(buildPage());

    await tester.tap(find.byKey(const Key('education-topic-redness')));
    await tester.pump();

    expect(find.text('Saat kemerahan disertai rasa perih atau panas'),
        findsOneWidget);
    expect(
        find.text('Mengapa jerawat tidak hilang dalam semalam?'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('education-search')),
      'topik yang tidak ada',
    );
    await tester.pump();

    expect(find.text('Topik belum ditemukan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
