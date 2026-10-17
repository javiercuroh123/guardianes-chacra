import 'dart:ui';

import 'package:flame/components.dart';

/// Un anillo que crece y se desvanece: el golpe en área de un guardián o el
/// destello de un impacto. Sale de un `ComponentPool` y vuelve solo al
/// terminar (se quita del mundo).
class PulseComponent extends PositionComponent {
  new() : super(anchor: Anchor.center, priority: 25);

  final Paint _fill = Paint();
  final Paint _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  Color _color = const Color(0xFFFFFFFF);
  double _maxRadius = 0;
  double _duration = 0.3;
  double _elapsed = 0;

  /// Empieza el anillo en [at] (píxeles del mundo).
  void start({
    required Vector2 at,
    required double radius,
    required Color color,
    double duration = 0.3,
  }) {
    position.setFrom(at);
    _maxRadius = radius;
    _color = color;
    _duration = duration;
    _elapsed = 0;
  }

  @override
  void update(double dt) {
    _elapsed += dt;
    if (_elapsed >= _duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_elapsed / _duration).clamp(0.0, 1.0);
    final radius = _maxRadius * (0.3 + 0.7 * t);
    final opacity = 1 - t;
    _fill.color = _color.withValues(alpha: 0.25 * opacity);
    _stroke.color = _color.withValues(alpha: 0.9 * opacity);
    canvas
      ..drawCircle(Offset.zero, radius, _fill)
      ..drawCircle(Offset.zero, radius, _stroke);
  }
}
