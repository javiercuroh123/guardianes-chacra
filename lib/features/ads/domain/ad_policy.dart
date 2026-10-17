/// Cuándo toca un anuncio intersticial: como máximo uno cada
/// `interstitialEvery` partidas terminadas (de `ads.json`), al salir de la
/// pantalla de resultado (ganar o perder). Nunca justo después de que el
/// jugador vio un anuncio recompensado en esa partida, para no encadenar
/// dos anuncios.
///
/// Dart puro: no sabe de AdMob ni de pantallas, solo cuenta partidas. Así
/// la regla se prueba sin teléfono.
class AdPolicy {
  int _finished = 0;

  /// Partidas terminadas desde el último intersticial.
  int get finishedSinceInterstitial => _finished;

  /// Se llama al salir del resultado de una partida. Devuelve si toca
  /// mostrar el intersticial ahora (y entonces la cuenta vuelve a 0).
  /// Con [interstitialEvery] en 0 nunca toca.
  bool resultClosed({
    required int interstitialEvery,
    required bool watchedRewarded,
  }) {
    _finished++;
    if (interstitialEvery <= 0 ||
        watchedRewarded ||
        _finished < interstitialEvery) {
      return false;
    }
    _finished = 0;
    return true;
  }
}
