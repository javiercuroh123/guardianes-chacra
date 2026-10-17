import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/features/ads/domain/ad_policy.dart';

void main() {
  test('un intersticial cada 3 partidas terminadas', () {
    final policy = AdPolicy();
    bool close() =>
        policy.resultClosed(interstitialEvery: 3, watchedRewarded: false);

    expect(
      [for (var i = 0; i < 7; i++) close()],
      [false, false, true, false, false, true, false],
    );
  });

  test('después de un recompensado no toca: queda para la siguiente', () {
    final policy = AdPolicy()
      ..resultClosed(interstitialEvery: 3, watchedRewarded: false)
      ..resultClosed(interstitialEvery: 3, watchedRewarded: false);

    expect(
      policy.resultClosed(interstitialEvery: 3, watchedRewarded: true),
      isFalse,
    );
    expect(policy.finishedSinceInterstitial, 3);
    expect(
      policy.resultClosed(interstitialEvery: 3, watchedRewarded: false),
      isTrue,
    );
    expect(policy.finishedSinceInterstitial, 0);
  });

  test('con 0 no hay intersticiales', () {
    final policy = AdPolicy();

    for (var i = 0; i < 10; i++) {
      expect(
        policy.resultClosed(interstitialEvery: 0, watchedRewarded: false),
        isFalse,
      );
    }
  });
}
