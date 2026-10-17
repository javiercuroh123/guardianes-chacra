import 'package:flutter/foundation.dart';

/// Los bloques de anuncios de AdMob que usa el juego.
@immutable
class AdUnitIds {
  const new({required this.rewarded, required this.interstitial});

  /// Los de prueba de Google: siempre muestran un anuncio de ejemplo y no
  /// cuentan como tráfico real (se pueden tocar sin problema).
  /// https://developers.google.com/admob/android/test-ads
  static const test = AdUnitIds(
    rewarded: 'ca-app-pub-3940256099942544/5224354917',
    interstitial: 'ca-app-pub-3940256099942544/1033173712',
  );

  final String rewarded;
  final String interstitial;

  /// Los IDs de esta compilación:
  ///
  /// - en debug y profile, siempre los de prueba (tocar anuncios reales
  ///   propios puede hacer que AdMob suspenda la cuenta);
  /// - en release, los reales que se pasan al compilar con
  ///   `--dart-define-from-file=admob.json` (ver `docs/MONETIZACION.md`).
  ///   Si faltan, `null`: la app sale sin anuncios en lugar de con los de
  ///   prueba.
  static AdUnitIds? forThisBuild() {
    if (!kReleaseMode) return test;
    const rewarded = String.fromEnvironment('ADMOB_REWARDED_ID');
    const interstitial = String.fromEnvironment('ADMOB_INTERSTITIAL_ID');
    if (rewarded.isEmpty || interstitial.isEmpty) return null;
    return const AdUnitIds(rewarded: rewarded, interstitial: interstitial);
  }
}
