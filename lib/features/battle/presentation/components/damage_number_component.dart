import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show FontWeight, TextStyle;
import 'package:guardianes_chacra/features/battle/presentation/style/battle_colors.dart';

const _fontSize = 30.0;

// En dos tonos, como las marcas de efectos: primero el borde oscuro y
// encima el relleno blanco.
final TextPaint _borderPaint = TextPaint(
  style: TextStyle(
    fontSize: _fontSize,
    fontWeight: FontWeight.w800,
    foreground: Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeJoin = StrokeJoin.round
      ..color = BattleColors.effectBorder,
  ),
);
final TextPaint _textPaint = TextPaint(
  style: const TextStyle(
    color: BattleColors.damageText,
    fontSize: _fontSize,
    fontWeight: FontWeight.w800,
  ),
);

/// Un número de daño que sube y se achica hasta desaparecer. Se reutiliza:
/// el juego lo saca de un `ComponentPool` con [start] y vuelve solo al
/// quitarse.
class DamageNumberComponent extends PositionComponent {
  new() : super(anchor: Anchor.center, priority: 40);

  /// Segundos en pantalla.
  static const lifetime = 0.6;

  /// Cuánto sube (píxeles del mundo) en ese tiempo.
  static const rise = 24.0;

  static final Vector2 _origin = Vector2.zero();

  final Vector2 _from = Vector2.zero();
  String _text = '';
  double _age = 0;

  String get text => _text;

  void start({required String text, required Vector2 at}) {
    _text = text;
    _age = 0;
    _from.setFrom(at);
    position.setFrom(at);
    scale.setAll(1);
  }

  @override
  void update(double dt) {
    _age += dt;
    if (_age >= lifetime) {
      removeFromParent();
      return;
    }
    final progress = _age / lifetime;
    position.setValues(_from.x, _from.y - rise * progress);
    // Se achica en el último tercio.
    scale.setAll(progress < 2 / 3 ? 1 : 3 * (1 - progress));
  }

  @override
  void render(Canvas canvas) {
    _borderPaint.render(canvas, _text, _origin, anchor: Anchor.center);
    _textPaint.render(canvas, _text, _origin, anchor: Anchor.center);
  }
}
