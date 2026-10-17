import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:guardianes_chacra/core/math/vec2.dart';
import 'package:guardianes_chacra/features/battle/domain/world/pest.dart';
import 'package:guardianes_chacra/features/battle/presentation/components/effect_marks.dart';
import 'package:guardianes_chacra/features/battle/presentation/components/interpolated.dart';
import 'package:guardianes_chacra/features/battle/presentation/components/sprite_body.dart';
import 'package:guardianes_chacra/features/battle/presentation/style/battle_colors.dart';
import 'package:guardianes_chacra/features/battle/presentation/style/battle_palette.dart';
import 'package:guardianes_chacra/features/content/domain/pest_def.dart';

final Paint _outlinePaint = Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 2
  ..color = BattleColors.outline;
final Paint _healthBackPaint = Paint()..color = BattleColors.healthBack;
final Paint _healthPaint = Paint()..color = BattleColors.health;
final Paint _flashBodyPaint = Paint()..color = const Color(0xFFFFFFFF);

/// Una plaga en pantalla: su sprite animado si tiene uno (mirando hacia
/// donde camina) o, si no, un círculo si camina y un rombo si vuela (el
/// jefe es más grande). Además, barra de vida, la marca de cada efecto
/// activo ([EffectMarks]) y un destello blanco al recibir daño.
///
/// Solo lee su [PestView]: no sabe nada de reglas. Todo lo que dibuja se
/// prepara al crearla, para no crear objetos en cada frame.
class PestComponent extends PositionComponent with Interpolated {
  new({required this.view, required this.tileSize, SpriteAnimation? animation})
    : _flying = view.def.tags.contains(PestTag.flying),
      _bodyPaint = Paint()..color = colorFor(view.def.id, view.def.color),
      _sprite = animation == null ? null : SpriteBody(animation),
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
    // El cuadro del sprite es una casilla (el del jefe, una y media).
    final side = tileSize * (view.def.boss ? 1.5 : 1.0);
    _spriteRect = Rect.fromCenter(center: _center, width: side, height: side);
    // Con sprite, la barra va justo encima de la imagen.
    final barTop = _sprite == null
        ? -8.0
        : math.min<double>(-8, _spriteRect.top + 4);
    _healthBar = Rect.fromLTWH(0, barTop, radius * 2, 4);
    _marks = EffectMarks(center: _center, radius: radius, headY: barTop - 8);
    resetInterpolation();
  }

  /// Cuánto dura el destello al recibir daño.
  static const flashSeconds = 0.08;

  final PestView view;
  final bool _flying;
  final Paint _bodyPaint;
  final SpriteBody? _sprite;
  late final double _radius;
  late final Offset _center;
  late final Path _diamond;
  late final Rect _spriteRect;
  late final Rect _healthBar;
  late final EffectMarks _marks;

  /// Segundos desde que apareció (para animar las marcas).
  double _age = 0;
  double _flash = 0;
  bool _facingLeft = false;
  double? _lastX;

  @override
  final double tileSize;

  int get pestId => view.id;

  bool get hasSprite => _sprite != null;
  bool get isFlashing => _flash > 0;
  bool get facingLeft => _facingLeft;

  /// Recibió daño: destella un instante.
  void flash() => _flash = flashSeconds;

  @override
  Vec2 get simulationPosition => view.position;

  @override
  void update(double dt) {
    super.update(dt);
    _sprite?.update(dt);
    _age += dt;
    if (_flash > 0) _flash = math.max(0, _flash - dt);
    // Mira hacia donde camina; si solo sube o baja, sigue como estaba.
    final lastX = _lastX;
    if (lastX != null) {
      final dx = position.x - lastX;
      if (dx < -0.01) {
        _facingLeft = true;
      } else if (dx > 0.01) {
        _facingLeft = false;
      }
    }
    _lastX = position.x;
  }

  @override
  void render(Canvas canvas) {
    _marks.render(
      canvas,
      slowed: view.hasEffect('slow'),
      burning: view.hasEffect('burn'),
      stunned: view.hasEffect('stun'),
      seconds: _age,
    );

    final sprite = _sprite;
    if (sprite != null) {
      sprite.render(canvas, _spriteRect, flipX: _facingLeft, flash: isFlashing);
    } else {
      final body = isFlashing ? _flashBodyPaint : _bodyPaint;
      if (_flying) {
        canvas
          ..drawPath(_diamond, body)
          ..drawPath(_diamond, _outlinePaint);
      } else {
        canvas
          ..drawCircle(_center, _radius, body)
          ..drawCircle(_center, _radius, _outlinePaint);
      }
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
