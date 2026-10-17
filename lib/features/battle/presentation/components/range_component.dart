import 'dart:ui';

import 'package:flame/components.dart';
import 'package:guardianes_chacra/features/battle/presentation/style/battle_colors.dart';

/// El círculo de alcance de un guardián (seleccionado o en vista previa).
class RangeComponent extends PositionComponent {
  new() : super(anchor: Anchor.center, priority: 8);

  final Paint _fill = Paint()..color = BattleColors.rangeFill;
  final Paint _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = BattleColors.rangeStroke;

  double _radius = 0;
  bool visible = false;

  void show({required Vector2 at, required double radius}) {
    position.setFrom(at);
    _radius = radius;
    visible = true;
  }

  void hide() => visible = false;

  @override
  void render(Canvas canvas) {
    if (!visible) return;
    canvas
      ..drawCircle(Offset.zero, _radius, _fill)
      ..drawCircle(Offset.zero, _radius, _stroke);
  }
}
