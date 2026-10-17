import 'package:guardianes_chacra/core/math/vec2.dart';

/// Camino que recorren las plagas. Cada plaga solo guarda cuánto avanzó
/// (su distancia); su posición se calcula aquí interpolando sobre el
/// camino. Así es fácil saber cuál va primera: la de mayor distancia.
class PathTrack {
  new(List<Vec2> points)
    : _points = List.unmodifiable(points),
      _cumulative = _cumulativeLengths(points) {
    if (points.length < 2) {
      throw ArgumentError.value(
        points,
        'points',
        'un camino necesita al menos dos puntos',
      );
    }
  }

  final List<Vec2> _points;

  /// `_cumulative[i]` = distancia desde el inicio hasta `_points[i]`.
  final List<double> _cumulative;

  double get length => _cumulative.last;

  /// Punto a [distance] casillas del inicio. Fuera del camino devuelve el
  /// extremo más cercano.
  Vec2 positionAt(double distance) {
    if (distance <= 0) return _points.first;
    if (distance >= length) return _points.last;

    // Búsqueda binaria del primer punto que está más allá de [distance].
    var low = 1;
    var high = _cumulative.length - 1;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (_cumulative[mid] > distance) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }

    // El tramo (low - 1 → low) contiene a [distance] y no mide cero.
    final start = _cumulative[low - 1];
    final t = (distance - start) / (_cumulative[low] - start);
    return _points[low - 1].lerp(_points[low], t);
  }

  static List<double> _cumulativeLengths(List<Vec2> points) {
    final lengths = <double>[0];
    for (var i = 1; i < points.length; i++) {
      lengths.add(lengths.last + points[i - 1].distanceTo(points[i]));
    }
    return List.unmodifiable(lengths);
  }
}
