import 'package:flutter/foundation.dart';
import 'package:guardianes_chacra/core/services/ads_service.dart';

/// Anuncios de mentira: cada test decide si hay uno cargado y si el jugador
/// lo ve entero; el servicio anota lo que se pidió mostrar.
class FakeAdsService implements AdsService {
  new({bool rewardedReady = true, this.earnReward = true})
    : status = ValueNotifier(AdsStatus(rewardedReady: rewardedReady));

  @override
  final ValueNotifier<AdsStatus> status;

  /// Si el jugador ve el recompensado hasta el final.
  bool earnReward;

  int rewardedShown = 0;
  int interstitialsShown = 0;
  int privacyOptionsShown = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> showRewarded() async {
    rewardedShown++;
    return earnReward;
  }

  @override
  Future<void> showInterstitial() async => interstitialsShown++;

  @override
  Future<void> showPrivacyOptions() async => privacyOptionsShown++;
}
