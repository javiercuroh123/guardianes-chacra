import 'dart:math' as math;
import 'dart:ui';

import 'package:guardianes_chacra/features/battle/presentation/style/battle_colors.dart';

Paint _stroke(Color color, double width) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeJoin = StrokeJoin.round
  ..color = color;

// Cada marca va en dos tonos: un borde oscuro ancho debajo y el color
// encima. Así se ve sobre el pasto, la tierra o el agua.
final Paint _borderPaint = _stroke(BattleColors.effectBorder, 5);
final Paint _slowPaint = _stroke(BattleColors.slow, 3);
final Paint _burnPaint = _stroke(BattleColors.burn, 3);
final Paint _dotBorderPaint = Paint()..color = BattleColors.effectBorder;
final Paint _stunPaint = Paint()..color = BattleColors.stun;

/// Las marcas de los efectos de estado de una plaga. Cada efecto tiene su
/// propia forma, no solo su color, para que se distingan aunque no se
/// vean los colores:
///
/// - lento: un anillo punteado;
/// - quemadura: una corona de puntas, como llamas;
/// - aturdido: tres puntos que giran sobre la cabeza.
///
/// Las formas se arman una vez al crear la plaga; en cada frame solo se
/// dibujan.
class EffectMarks {
  /// [center] y [radius] son los del cuerpo de la plaga; [headY], la
  /// altura a la que giran los puntos de aturdido.
  new({required Offset center, required double radius, required double headY})
    : _orbit = Offset(center.dx, headY),
      _orbitRadius = Size(radius * 0.8, 4),
      slow = _dashedRing(center, radius + 5),
      burn = _flameCrown(center, inner: radius + 9, outer: radius + 14);

  /// Las rayas del anillo punteado.
  static const dashes = 12;

  /// Las puntas de la corona.
  static const flames = 10;

  /// Cuánto tarda una vuelta de los puntos de aturdido.
  static const stunTurnSeconds = 1.2;

  final Offset _orbit;
  final Size _orbitRadius;

  final Path slow;
  final Path burn;

  /// Dónde está el punto [index] (0–2) de aturdido a los [seconds].
  Offset stunDot(int index, double seconds) {
    final angle =
        seconds / stunTurnSeconds * 2 * math.pi + index * 2 * math.pi / 3;
    return Offset(
      _orbit.dx + _orbitRadius.width * math.cos(angle),
      _orbit.dy + _orbitRadius.height * math.sin(angle),
    );
  }

  void render(
    Canvas canvas, {
    required bool slowed,
    required bool burning,
    required bool stunned,
    required double seconds,
  }) {
    if (slowed) {
      canvas
        ..drawPath(slow, _borderPaint)
        ..drawPath(slow, _slowPaint);
    }
    if (burning) {
      canvas
        ..drawPath(burn, _borderPaint)
        ..drawPath(burn, _burnPaint);
    }
    if (stunned) {
      for (var i = 0; i < 3; i++) {
        final dot = stunDot(i, seconds);
        canvas
          ..drawCircle(dot, 4, _dotBorderPaint)
          ..drawCircle(dot, 2.5, _stunPaint);
      }
    }
  }

  static Path _dashedRing(Offset center, double radius) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    const step = 2 * math.pi / dashes;
    final path = Path();
    for (var i = 0; i < dashes; i++) {
      // Cada raya ocupa media porción; la otra mitad es el hueco.
      path.addArc(rect, i * step, step / 2);
    }
    return path;
  }

  static Path _flameCrown(
    Offset center, {
    required double inner,
    required double outer,
  }) {
    const step = math.pi / flames;
    final path = Path();
    for (var i = 0; i < flames * 2; i++) {
      // Las puntas (pares) hacia afuera; los valles (impares), adentro.
      final radius = i.isEven ? outer : inner;
      final angle = i * step - math.pi / 2;
      final point =
          center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }
}
