import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinsight/data/skin_demo_data.dart';
import 'package:skinsight/data/skin_journey_store.dart';
import 'package:skinsight/features/education/presentation/education_result_screen.dart';
import 'package:skinsight/pages/skin_result_page.dart';
import 'package:skinsight/shared/widgets/skin_face_detection_overlay.dart';
import 'package:skinsight/theme/skin_theme.dart';
import 'package:skinsight/widgets/skin_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final pngBytes = Uint8List.fromList(base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
  ));

  testWidgets(
      'SkinResultPage preserves detection overlay and opens EducationResultScreen',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final store = SkinJourneyStore.instance;
    store.answers.clear();
    store.answers['M03'] = 'Sedang-berat';
    addTearDown(store.answers.clear);

    final analysis = SkinDemoData.forPhoto(pngBytes);

    await tester.pumpWidget(
      MaterialApp(
        theme: SkinTokens.theme(),
        home: SkinResultPage(
          selfieBytes: pngBytes,
          analysis: analysis,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Memastikan overlay Face ROI & lingkaran tetap aktif dan tidak kembali ke mesh.
    expect(find.byType(SkinFaceDetectionOverlay), findsOneWidget);
    expect(find.byType(SkinScanMesh), findsNothing);

    // Label jenis kulit bahasa Indonesia tampil konsisten di lencana dan kartu.
    expect(find.text('Jenis kulit: Kering'), findsOneWidget);
    expect(find.text('Kering'), findsOneWidget);

    // Membuka halaman detail edukasi lewat tombol pada kartu Edukasi perawatan.
    final openBtn = find.byKey(const Key('open-education-result'));
    await tester.scrollUntilVisible(
      openBtn,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(openBtn);
    await tester.pumpAndSettle();

    expect(find.byType(EducationResultScreen), findsOneWidget);
    expect(find.text('Hasil Edukasi'), findsOneWidget);
    expect(find.text('Jerawat'), findsOneWidget);

    final careNotice = find.textContaining('utamakan arahan tenaga kesehatan');
    await tester.scrollUntilVisible(
      careNotice,
      300,
      scrollable: find.descendant(
        of: find.byKey(const Key('education-result-list')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(careNotice, findsOneWidget);

    // Kembali ke hasil analisis lewat tombol bawah.
    await tester.tap(find.byKey(const Key('education-result-done')));
    await tester.pumpAndSettle();
    expect(find.byType(SkinResultPage), findsOneWidget);

    // Pintasan 'Rekomendasi perawatan' pada kartu foto juga membuka EducationResultScreen.
    final shortcut = find.text('Rekomendasi perawatan');
    await tester.ensureVisible(shortcut);
    await tester.tap(shortcut);
    await tester.pumpAndSettle();
    expect(find.byType(EducationResultScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
