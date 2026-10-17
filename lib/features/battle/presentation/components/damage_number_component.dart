import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show FontWeight, Shadow, TextStyle;

final TextPaint _textPaint = TextPaint(
  style: const TextStyle(
    color: Color(0xFFFFFFFF),
    fontSize: 30,
    fontWeight: FontWeight.w800,
    shadows: [Shadow(blurRadius: 3)],
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
  void render(Canvas canvas) =>
      _textPaint.render(canvas, _text, Vector2.zero(), anchor: Anchor.center);
}
