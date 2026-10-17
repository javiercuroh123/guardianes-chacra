/// Tiempo de recarga de un ataque, en ticks. Empieza listo.
class Cooldown {
  new(this.durationTicks);

  final int durationTicks;
  double _remaining = 0;

  /// Avanza un tick a la velocidad [speed] (1 = normal, 1,5 = +50 %) y
  /// dice si el ataque está listo.
  bool advance(double speed) {
    if (_remaining > 0) _remaining -= speed;
    return _remaining <= 1e-9;
  }

  /// Se llama al atacar: vuelve a esperar la recarga completa.
  void restart() => _remaining = durationTicks.toDouble();
}
