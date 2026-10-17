import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:guardianes_chacra/core/services/ad_unit_ids.dart';
import 'package:guardianes_chacra/core/services/ads_service.dart';

/// Los anuncios reales, con `google_mobile_ads` (AdMob) y su formulario de
/// consentimiento (UMP):
///
/// 1. Al arrancar se actualiza la información de consentimiento y, donde
///    la ley lo exige (por ejemplo, en Europa), se muestra el formulario.
/// 2. Solo si `canRequestAds()` lo permite se inicializa el SDK y se
///    cargan anuncios. Si el consentimiento ya se dio en una sesión
///    anterior, empiezan a cargar sin esperar al formulario.
/// 3. Se mantiene listo un anuncio de cada tipo: al cerrarse uno, se carga
///    el siguiente; si falla la carga, se reintenta en 30 s.
///
/// Todos los anuncios piden contenido apto para todo público
/// (clasificación G), aunque el juego se declare para mayores de 13 años.
class GoogleAdsService implements AdsService {
  new({required this._ids, this._consentDebug});

  static const _retryDelay = Duration(seconds: 30);

  final AdUnitIds _ids;

  /// Para probar el formulario como si el teléfono estuviera en Europa
  /// (ver [consentDebugFromEnvironment]).
  final ConsentDebugSettings? _consentDebug;

  final ValueNotifier<AdsStatus> _status = ValueNotifier(const AdsStatus());
  RewardedAd? _rewarded;
  InterstitialAd? _interstitial;
  var _started = false;
  var _loadingRewarded = false;
  var _loadingInterstitial = false;

  @override
  ValueListenable<AdsStatus> get status => _status;

  @override
  Future<void> initialize() async {
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(consentDebugSettings: _consentDebug),
      () => ConsentForm.loadAndShowConsentFormIfRequired((error) {
        if (error != null) _log('formulario de consentimiento', error.message);
        unawaited(_afterConsent());
      }),
      (error) {
        _log('información de consentimiento', error.message);
        unawaited(_afterConsent());
      },
    );
    // El consentimiento de una sesión anterior ya sirve: los anuncios
    // empiezan a cargar mientras se actualiza.
    if (await ConsentInformation.instance.canRequestAds()) await _start();
  }

  Future<void> _afterConsent() async {
    final privacy = await ConsentInformation.instance
        .getPrivacyOptionsRequirementStatus();
    _status.value = _status.value.copyWith(
      privacyOptionsRequired:
          privacy == PrivacyOptionsRequirementStatus.required,
    );
    if (await ConsentInformation.instance.canRequestAds()) await _start();
  }

  Future<void> _start() async {
    if (_started) return;
    _started = true;
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(maxAdContentRating: MaxAdContentRating.g),
    );
    await MobileAds.instance.initialize();
    _loadRewarded();
    _loadInterstitial();
  }

  void _loadRewarded() {
    if (_loadingRewarded || _rewarded != null) return;
    _loadingRewarded = true;
    unawaited(
      RewardedAd.load(
        adUnitId: _ids.rewarded,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _loadingRewarded = false;
            _rewarded = ad;
            _status.value = _status.value.copyWith(rewardedReady: true);
          },
          onAdFailedToLoad: (error) {
            _loadingRewarded = false;
            _log('anuncio recompensado', error.message);
            Timer(_retryDelay, _loadRewarded);
          },
        ),
      ),
    );
  }

  void _loadInterstitial() {
    if (_loadingInterstitial || _interstitial != null) return;
    _loadingInterstitial = true;
    unawaited(
      InterstitialAd.load(
        adUnitId: _ids.interstitial,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _loadingInterstitial = false;
            _interstitial = ad;
          },
          onAdFailedToLoad: (error) {
            _loadingInterstitial = false;
            _log('intersticial', error.message);
            Timer(_retryDelay, _loadInterstitial);
          },
        ),
      ),
    );
  }

  @override
  Future<bool> showRewarded() async {
    final ad = _rewarded;
    if (ad == null) return false;
    _rewarded = null;
    _status.value = _status.value.copyWith(rewardedReady: false);

    var earned = false;
    final closed = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        unawaited(ad.dispose());
        closed.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _log('mostrar el recompensado', error.message);
        unawaited(ad.dispose());
        closed.complete();
      },
    );
    await ad.show(onUserEarnedReward: (_, _) => earned = true);
    await closed.future;
    _loadRewarded();
    return earned;
  }

  @override
  Future<void> showInterstitial() async {
    final ad = _interstitial;
    if (ad == null) return;
    _interstitial = null;

    final closed = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        unawaited(ad.dispose());
        closed.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _log('mostrar el intersticial', error.message);
        unawaited(ad.dispose());
        closed.complete();
      },
    );
    await ad.show();
    await closed.future;
    _loadInterstitial();
  }

  @override
  Future<void> showPrivacyOptions() async {
    await ConsentForm.showPrivacyOptionsForm((error) {
      if (error != null) _log('opciones de privacidad', error.message);
    });
    await _afterConsent();
  }

  /// Un anuncio que no carga no es un error del juego: se avisa en la
  /// consola y se sigue sin él.
  static void _log(String what, String message) =>
      debugPrint('Anuncios: falló $what: $message');

  /// Para probar el formulario de consentimiento como en Europa, fuera de
  /// release:
  ///
  ///     flutter run --dart-define=UMP_TEST_DEVICE=<id del log>
  ///
  /// El id (hasheado) lo imprime el SDK en logcat la primera vez. Ver
  /// `docs/MONETIZACION.md`.
  static ConsentDebugSettings? consentDebugFromEnvironment() {
    const device = String.fromEnvironment('UMP_TEST_DEVICE');
    if (kReleaseMode || device.isEmpty) return null;
    return ConsentDebugSettings(
      debugGeography: DebugGeography.debugGeographyEea,
      testIdentifiers: [device],
    );
  }
}
