import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

/// Pinta en blanco lo que se dibuja (el destello al recibir daño).
final Paint flashPaint = Paint()
  ..colorFilter = const ColorFilter.mode(Color(0xFFFFFFFF), BlendMode.srcATop);

/// El cuerpo animado de una plaga o un guardián, si tiene sprite. Cada
/// componente lleva su propio reloj de animación (el `ticker`), así dos
/// plagas iguales no se mueven al unísono.
class SpriteBody {
  new(SpriteAnimation animation) : _ticker = animation.createTicker();

  final SpriteAnimationTicker _ticker;

  void update(double dt) => _ticker.update(dt);

  /// Dibuja el cuadro actual en [rect]; con [flipX], espejado (mira a la
  /// izquierda). Con [flash], en blanco.
  void render(
    Canvas canvas,
    Rect rect, {
    bool flipX = false,
    bool flash = false,
  }) {
    final sprite = _ticker.getSprite();
    if (flipX) {
      canvas
        ..save()
        ..translate(rect.center.dx, 0)
        ..scale(-1, 1)
        ..translate(-rect.center.dx, 0);
    }
    sprite.render(
      canvas,
      position: Vector2(rect.left, rect.top),
      size: Vector2(rect.width, rect.height),
      overridePaint: flash ? flashPaint : null,
    );
    if (flipX) canvas.restore();
  }
}
