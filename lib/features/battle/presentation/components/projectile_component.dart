import 'dart:ui';

import 'package:flame/components.dart';
import 'package:guardianes_chacra/core/math/vec2.dart';
import 'package:guardianes_chacra/features/battle/domain/world/projectile.dart';
import 'package:guardianes_chacra/features/battle/presentation/components/interpolated.dart';
import 'package:guardianes_chacra/features/battle/presentation/style/battle_colors.dart';

const double _radius = 5;
const Offset _center = Offset(_radius, _radius);
final Paint _paint = Paint()..color = BattleColors.projectile;
final Paint _outline = Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 1.5
  ..color = BattleColors.outline;

/// Un proyectil en vuelo. Sale de un `ComponentPool`: al quitarlo del
/// mundo vuelve al pool y se reutiliza con otro [ProjectileView].
class ProjectileComponent extends PositionComponent with Interpolated {
  new()
    : super(
        anchor: Anchor.center,
        size: Vector2.all(_radius * 2),
        priority: 30,
      );

  late ProjectileView _view;

  @override
  late double tileSize;

  ProjectileView get view => _view;

  /// Prepara el componente (nuevo o reciclado) para seguir a [view].
  void follow(ProjectileView view, {required double tileSize}) {
    _view = view;
    this.tileSize = tileSize;
    resetInterpolation();
  }

  @override
  Vec2 get simulationPosition => view.position;

  @override
  void render(Canvas canvas) {
    canvas
      ..drawCircle(_center, _radius, _paint)
      ..drawCircle(_center, _radius, _outline);
  }
}
