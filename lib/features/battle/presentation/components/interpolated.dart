import 'package:flame/components.dart';
import 'package:guardianes_chacra/core/math/vec2.dart';

/// Un componente que sigue a algo de la simulación y se dibuja entre su
/// posición del tick anterior y la actual.
///
/// La simulación avanza 30 veces por segundo, pero la pantalla se dibuja a
/// 60 o 120: sin interpolar, las plagas se moverían a saltos. Se dibuja un
/// tick atrasado (33 ms), algo que no se nota.
mixin Interpolated on PositionComponent {
  final Vector2 _previous = Vector2.zero();
  final Vector2 _current = Vector2.zero();

  /// Posición en la simulación, en casillas.
  Vec2 get simulationPosition;

  /// Píxeles del mundo por casilla.
  double get tileSize;

  /// Arranca sin movimiento previo (al aparecer).
  void resetInterpolation() {
    _read(_current);
    _previous.setFrom(_current);
    position.setFrom(_current);
  }

  /// Se llama justo antes del último paso de la simulación de este frame.
  void rememberPrevious() => _read(_previous);

  /// Se llama después de los pasos de la simulación.
  void readCurrent() => _read(_current);

  /// Ubica el componente a una fracción [alpha] entre los dos ticks.
  void interpolate(double alpha) {
    position
      ..x = _previous.x + (_current.x - _previous.x) * alpha
      ..y = _previous.y + (_current.y - _previous.y) * alpha;
  }

  void _read(Vector2 into) {
    final at = simulationPosition;
    into.setValues(at.x * tileSize, at.y * tileSize);
  }
}
