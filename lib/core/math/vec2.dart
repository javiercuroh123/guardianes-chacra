import 'dart:math' as math;

import 'package:meta/meta.dart';

/// Punto o vector 2D inmutable de la simulación, en casillas del mapa.
///
/// Es Dart puro a propósito: el `Vector2` de Flame es mutable y vive en la
/// capa visual; la simulación no debe depender de él.
@immutable
class Vec2 {
  const new(this.x, this.y);

  final double x;
  final double y;

  /// `sqrt` está redondeada correctamente por IEEE 754: da el mismo
  /// resultado en todas las plataformas, a diferencia de `sin` o `atan2`.
  double distanceTo(Vec2 other) {
    final dx = other.x - x;
    final dy = other.y - y;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Punto a una fracción [t] del camino hacia [to] (0 = aquí, 1 = [to]).
  Vec2 lerp(Vec2 to, double t) => Vec2(x + (to.x - x) * t, y + (to.y - y) * t);

  @override
  bool operator ==(Object other) =>
      other is Vec2 && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => '($x, $y)';
}
