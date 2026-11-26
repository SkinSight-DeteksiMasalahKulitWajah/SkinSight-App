import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:skinsight/core/cache/local_cache.dart';
import 'package:skinsight/features/history/data/skin_history_repository.dart';
import 'package:skinsight/features/journeys/data/skin_journey_store.dart';

/// Tunggu jeda simpan cache (debounce 600 ms) plus penulisan berkas.
Future<void> _waitForCacheWrite() =>
    Future<void>.delayed(const Duration(milliseconds: 1200));

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('skinsight_cache_test');
    LocalCache.instance.overrideRoot = tmp;
    LocalCache.instance.useUser('user-a');
    SkinHistoryRepository.instance.clearLocal();
    SkinJourneyStore.instance.clearLocal();
  });

  tearDown(() async {
    await LocalCache.instance.clearUser();
    LocalCache.instance.overrideRoot = null;
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  test('riwayat scan dan foto pulih dari cache setelah memori dikosongkan',
      () async {
    final history = SkinHistoryRepository.instance;
    final photo = Uint8List.fromList(List<int>.generate(256, (i) => i % 256));

    final saved = await history.saveLatest(photo,
        findings: const ['Acne'],
        skinType: 'Oily',
        modelConnected: true,
        detectionCounts: const {'Acne': 3},
        modelVersion: 'test-1');
    await _waitForCacheWrite();

    // Simulasi aplikasi dibuka ulang tanpa koneksi: memori kosong, lalu cache dimuat.
    history.clearLocal();
    expect(history.records, isEmpty);
    await history.loadFromCache();

    expect(history.records, hasLength(1));
    final restored = history.records.single;
    expect(restored.id, saved.id);
    expect(restored.visualFindings, ['Acne']);
    expect(restored.detectionCounts, {'Acne': 3});
    expect(restored.selfieBytes, photo);
  });

  test('journey beserta fotonya pulih dari cache', () async {
    final store = SkinJourneyStore.instance;
    final photo = Uint8List.fromList(List<int>.generate(300, (i) => 255 - i % 256));
    store.addPhoto(photo,
        visualFindings: const ['PIH'],
        modelConnected: true,
        detectionCounts: const {'PIH': 2},
        modelVersion: 'test-1');
    final journeyId = store.selectedJourney.id;
    await _waitForCacheWrite();

    store.clearLocal();
    expect(store.journeys, isEmpty);
    await store.loadFromCache();

    final restored = store.journeys.singleWhere((j) => j.id == journeyId);
    expect(restored.photos, hasLength(1));
    expect(restored.photos.single.bytes, photo);
    expect(restored.photos.single.detectionCounts, {'PIH': 2});
    expect(store.selectedJourney.id, journeyId);
  });

  test('keluar akun menghapus seluruh cache pengguna', () async {
    await LocalCache.instance.writeJson('profile', {'full_name': 'Alea'});
    final userDir = Directory('${tmp.path}/skinsight_cache/user-a');
    expect(await userDir.exists(), isTrue);

    await LocalCache.instance.clearUser();
    expect(await userDir.exists(), isFalse);
    expect(LocalCache.instance.isActive, isFalse);
  });

  test('cache terpisah per pengguna', () async {
    await LocalCache.instance.writeJson('profile', {'full_name': 'Alea'});
    LocalCache.instance.useUser('user-b');
    expect(await LocalCache.instance.readJson('profile'), isNull);
  });
}
