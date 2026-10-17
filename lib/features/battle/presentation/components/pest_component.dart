import 'dart:ui';

import 'package:flame/components.dart';
import 'package:guardianes_chacra/core/math/vec2.dart';
import 'package:guardianes_chacra/features/battle/domain/world/pest.dart';
import 'package:guardianes_chacra/features/battle/presentation/components/interpolated.dart';
import 'package:guardianes_chacra/features/battle/presentation/style/battle_colors.dart';
import 'package:guardianes_chacra/features/battle/presentation/style/battle_palette.dart';
import 'package:guardianes_chacra/features/content/domain/pest_def.dart';

final Paint _outlinePaint = Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 2
  ..color = BattleColors.outline;
final Paint _healthBackPaint = Paint()..color = BattleColors.healthBack;
final Paint _healthPaint = Paint()..color = BattleColors.health;

Paint _ring(Color color) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 3
  ..color = color;
final Paint _slowPaint = _ring(BattleColors.slow);
final Paint _burnPaint = _ring(BattleColors.burn);
final Paint _stunPaint = _ring(BattleColors.stun);

/// Una plaga en pantalla: círculo si camina, rombo si vuela (el jefe es más
/// grande), barra de vida y un anillo por cada efecto activo.
///
/// Solo lee su [PestView]: no sabe nada de reglas. Todo lo que dibuja se
/// prepara al crearla, para no crear objetos en cada frame.
class PestComponent extends PositionComponent with Interpolated {
  new({required this.view, required this.tileSize})
    : _flying = view.def.tags.contains(PestTag.flying),
      _bodyPaint = Paint()..color = colorFor(view.def.id, view.def.color),
      super(anchor: Anchor.center, priority: 20) {
    final radius = tileSize * (view.def.boss ? 0.42 : (_flying ? 0.26 : 0.28));
    size = Vector2.all(radius * 2);
    _radius = radius;
    _center = Offset(radius, radius);
    _diamond = Path()
      ..moveTo(radius, 0)
      ..lineTo(radius * 2, radius)
      ..lineTo(radius, radius * 2)
      ..lineTo(0, radius)
      ..close();
    _healthBar = Rect.fromLTWH(0, -8, radius * 2, 4);
    resetInterpolation();
  }

  final PestView view;
  final bool _flying;
  final Paint _bodyPaint;
  late final double _radius;
  late final Offset _center;
  late final Path _diamond;
  late final Rect _healthBar;

  @override
  final double tileSize;

  int get pestId => view.id;

  @override
  Vec2 get simulationPosition => view.position;

  @override
  void render(Canvas canvas) {
    var ring = _radius + 3;
    if (view.hasEffect('slow')) {
      canvas.drawCircle(_center, ring, _slowPaint);
      ring += 3;
    }
    if (view.hasEffect('burn')) {
      canvas.drawCircle(_center, ring, _burnPaint);
      ring += 3;
    }
    if (view.hasEffect('stun')) {
      canvas.drawCircle(_center, ring, _stunPaint);
    }

    if (_flying) {
      canvas
        ..drawPath(_diamond, _bodyPaint)
        ..drawPath(_diamond, _outlinePaint);
    } else {
      canvas
        ..drawCircle(_center, _radius, _bodyPaint)
        ..drawCircle(_center, _radius, _outlinePaint);
    }

    final health = (view.health / view.def.maxHealth).clamp(0.0, 1.0);
    if (health < 1) {
      canvas
        ..drawRect(_healthBar, _healthBackPaint)
        // Se escala la barra completa en lugar de crear un Rect nuevo.
        ..save()
        ..scale(health, 1)
        ..drawRect(_healthBar, _healthPaint)
        ..restore();
    }
  }
}
