import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:guardianes_chacra/features/battle/presentation/style/battle_colors.dart';

/// El círculo de alcance de un guardián (seleccionado o en vista previa):
/// relleno turquesa muy suave y un borde punteado, con un contorno oscuro
/// debajo para que se lea sobre el pasto y sobre la tierra.
class RangeComponent extends PositionComponent {
  new() : super(anchor: Anchor.center, priority: 8);

  /// Largo aproximado de cada trazo y de cada hueco, en píxeles del mapa.
  static const double dash = 9;

  final Paint _fill = Paint()..color = BattleColors.rangeFill;
  final Paint _outline = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4.5
    ..strokeCap = StrokeCap.round
    ..color = BattleColors.rangeOutline;
  final Paint _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round
    ..color = BattleColors.rangeStroke;

  double _radius = 0;
  Path _dashes = Path();
  bool visible = false;

  void show({required Vector2 at, required double radius}) {
    position.setFrom(at);
    if (radius != _radius) {
      _radius = radius;
      _dashes = _dashedCircle(radius);
    }
    visible = true;
  }

  void hide() => visible = false;

  /// El borde como arcos cortos: un número par de trazos que da la vuelta
  /// justa, para que no queden dos trazos pegados donde se cierra.
  static Path _dashedCircle(double radius) {
    final path = Path();
    if (radius <= 0) return path;
    final count = math.max(8, (2 * math.pi * radius / (dash * 2)).round());
    final step = 2 * math.pi / count;
    final rect = Rect.fromCircle(center: Offset.zero, radius: radius);
    for (var i = 0; i < count; i++) {
      path.addArc(rect, i * step, step / 2);
    }
    return path;
  }

  @override
  void render(Canvas canvas) {
    if (!visible) return;
    canvas
      ..drawCircle(Offset.zero, _radius, _fill)
      ..drawPath(_dashes, _outline)
      ..drawPath(_dashes, _stroke);
  }
}
