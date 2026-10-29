import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skinsight/core/app_assets.dart';
import 'package:skinsight/pages/onboarding/onboarding_hero.dart';
import 'package:skinsight/theme/skin_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('semua aset wajib terdaftar di AssetManifest dan tidak ada di lib/',
      () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets()..sort();
    debugPrint(
        'AssetManifest (${assets.length} aset):\n  ${assets.join('\n  ')}');

    for (final asset in AppAssets.bundled) {
      expect(assets, contains(asset), reason: '$asset belum dibundel');
    }
    expect(
      assets.where((asset) => asset.startsWith('lib/')),
      isEmpty,
      reason: 'Aset harus berada di folder assets/ di root project.',
    );
  });

  test('AppAssets.exists sesuai isi manifest untuk foto opsional', () async {
    AppAssets.resetManifestCache();
    final listed =
        (await AssetManifest.loadFromAssetBundle(rootBundle)).listAssets();
    for (final asset in AppAssets.optional) {
      expect(await AppAssets.exists(asset), listed.contains(asset));
    }
  });

  testWidgets('layar pembuka memakai foto potret & aloe 3D yang dibundel',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(MaterialApp(
      theme: SkinTokens.theme(),
      home: Scaffold(body: OnboardingHero(onStart: () {}, onLogin: () {})),
    ));
    await tester.pumpAndSettle();

    String? assetName(ImageProvider provider) {
      final inner = provider is ResizeImage ? provider.imageProvider : provider;
      return inner is AssetImage ? inner.assetName : null;
    }

    final names = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => assetName(image.image))
        .toSet();
    expect(names, contains(AppAssets.heroPortrait));
    expect(names, contains(AppAssets.aloe3d));
    expect(tester.takeException(), isNull);
  });
}
