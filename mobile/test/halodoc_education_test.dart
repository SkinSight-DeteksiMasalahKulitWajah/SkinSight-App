import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinsight/features/education/data/halodoc_education.dart';
import 'package:skinsight/features/education/presentation/widgets/halodoc_education_section.dart';

Widget _host(List<String> findings) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: HalodocEducationSection(findings: findings),
        ),
      ),
    );

void main() {
  test('setiap kelas deteksi punya edukasi dan tautan Halodoc', () {
    for (final key in ['Acne', 'PIH', 'Dark Circle', 'Redness', 'Wrinkle']) {
      final edu = halodocEducation[key];
      expect(edu, isNotNull, reason: key);
      expect(edu!.url, startsWith('https://www.halodoc.com/'));
      expect(edu.sections, isNotEmpty);
    }
  });

  testWidgets('hanya menampilkan temuan pengguna, temuan pertama terbuka',
      (tester) async {
    await tester.pumpWidget(_host(['Acne', 'Dark Circle']));
    await tester.pumpAndSettle();

    expect(find.text('Edukasi Jerawat'), findsOneWidget);
    expect(find.text('Edukasi Mata Panda'), findsOneWidget);
    expect(find.text('Edukasi Keriput & Garis Halus'), findsNothing);
    // Accordion pertama terbuka: tombol ke Halodoc terlihat.
    expect(find.byKey(const Key('halodoc-link-Acne')), findsOneWidget);
    expect(find.byKey(const Key('halodoc-link-Dark Circle')), findsNothing);

    await tester.ensureVisible(find.text('Edukasi Mata Panda'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edukasi Mata Panda'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('halodoc-link-Dark Circle')), findsOneWidget);
  });

  testWidgets('tanpa temuan dikenali, semua edukasi umum tampil tertutup',
      (tester) async {
    await tester.pumpWidget(_host(const []));
    await tester.pumpAndSettle();

    for (final edu in halodocEducation.values) {
      expect(find.text(edu.title), findsOneWidget);
    }
    expect(find.text('Baca di Halodoc'), findsNothing);
  });
}
