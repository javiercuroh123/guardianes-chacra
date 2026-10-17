/// Decide si un sonido puede sonar ahora, para que una ráfaga de disparos o
/// de plagas derrotadas no sature el audio:
///
/// - el mismo sonido, como mucho una vez cada [minInterval];
/// - entre todos, como mucho [maxPerWindow] dentro de cada [window].
///
/// Es Dart puro y recibe el reloj (`now`) para poder probarlo.
class SoundLimiter<K> {
  new({
    required this._now,
    this.minInterval = const Duration(milliseconds: 70),
    this.maxPerWindow = 6,
    this.window = const Duration(milliseconds: 250),
  });

  final Duration Function() _now;
  final Duration minInterval;
  final int maxPerWindow;
  final Duration window;

  final Map<K, Duration> _lastPlayed = {};

  /// Momentos de los últimos sonidos permitidos (los de la ventana actual).
  final List<Duration> _recent = [];

  /// Si [sound] puede sonar ahora. Si puede, queda anotado.
  bool tryPlay(K sound) {
    final now = _now();
    final last = _lastPlayed[sound];
    if (last != null && now - last < minInterval) return false;

    _recent.removeWhere((time) => now - time >= window);
    if (_recent.length >= maxPerWindow) return false;

    _recent.add(now);
    _lastPlayed[sound] = now;
    return true;
  }
}
