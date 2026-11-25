import 'package:flutter_test/flutter_test.dart';
import 'package:skinsight/core/api/api_client.dart';
import 'package:skinsight/features/education/data/recommendation_service.dart';

void main() {
  tearDown(ApiClient.instance.resetCircuitBreaker);

  test('langsung gagal tanpa menunggu bila server ditandai tidak terjangkau',
      () async {
    ApiClient.instance.markUnreachable();
    expect(ApiClient.instance.isReachableNow, isFalse);

    final watch = Stopwatch()..start();
    await expectLater(
      RecommendationService.instance.getRecommendation(scanData: const {}),
      throwsA(isA<Exception>().having(
          (e) => e.toString(), 'pesan', contains('tidak terjangkau'))),
    );
    expect(watch.elapsed, lessThan(const Duration(seconds: 1)));
  });
}
