import 'package:guardianes_chacra/features/battle/domain/engine/sim_time.dart';

enum GameSpeed {
  normal(1),
  fast(2);

  new(this.multiplier);

  final int multiplier;
}

/// Traduce el tiempo real de cada frame en pasos fijos de simulación.
///
/// Flame llamará `advance(dt)` en cada frame y ejecutará `step()` tantas
/// veces como indique. La velocidad x2 solo cambia cuántos pasos se dan,
/// no su duración: la partida termina igual que a x1, solo antes.
class FixedStepClock {
  new({this.maxStepsPerUpdate = 8});

  /// Tope de pasos por frame. Si el teléfono se traba (o la app vuelve del
  /// segundo plano), ponerse al día de golpe trabaría aún más el siguiente
  /// frame; mejor descartar ese atraso.
  final int maxStepsPerUpdate;

  GameSpeed speed = GameSpeed.normal;
  bool paused = false;

  /// Ticks acumulados que todavía no completan un paso, en [0, 1).
  double _pendingTicks = 0;

  // Tolerancia para que, por ejemplo, 60 frames de 1/60 s den exactamente
  // 30 pasos aunque la suma de decimales quede en 29,9999999.
  static const _epsilon = 1e-9;

  /// Avanza [seconds] de tiempo real y devuelve cuántos pasos dar.
  int advance(double seconds) {
    if (paused) return 0;

    _pendingTicks += seconds * ticksPerSecond * speed.multiplier;
    var steps = (_pendingTicks + _epsilon).floor();
    _pendingTicks = _pendingTicks - steps < 0 ? 0 : _pendingTicks - steps;

    if (steps > maxStepsPerUpdate) {
      steps = maxStepsPerUpdate;
      _pendingTicks = 0;
    }
    return steps;
  }

  /// Fracción del camino hacia el siguiente paso, en [0, 1). La capa visual
  /// la usa para dibujar entre la posición del tick anterior y la actual.
  double get alpha => _pendingTicks;
}
