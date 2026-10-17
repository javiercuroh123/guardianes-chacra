import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart' show FontWeight, TextStyle;
import 'package:guardianes_chacra/features/battle/domain/world/guardian.dart';
import 'package:guardianes_chacra/features/battle/presentation/battle_game.dart';
import 'package:guardianes_chacra/features/battle/presentation/components/sprite_body.dart';
import 'package:guardianes_chacra/features/battle/presentation/style/battle_colors.dart';
import 'package:guardianes_chacra/features/battle/presentation/style/battle_palette.dart';
import 'package:guardianes_chacra/features/content/domain/sprite_def.dart';

final Paint _outlinePaint = Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 2
  ..color = BattleColors.outline;
final Paint _selectedPaint = Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 3
  ..color = BattleColors.selection;
final Paint _pipPaint = Paint()..color = BattleColors.selection;

/// Velocidad de giro hacia el objetivo (radianes por segundo).
const double _turnSpeed = 14;

/// Un guardián en pantalla: un cuadrado de su color con su inicial, puntos
/// que indican su nivel y, si ataca, una "honda" que gira hacia su
/// objetivo. Si su nivel o rama tiene sprite, se dibuja el sprite en vez
/// del cuadrado y la inicial. Al tocarlo avisa al juego; no decide nada.
class GuardianComponent extends PositionComponent
    with TapCallbacks, HasGameReference<BattleGame> {
  new({
    required this.view,
    required double tileSize,
    required String label,
    this.animationFor = _noAnimation,
  }) : _hasAim = view.def.levels.first.targets.isNotEmpty,
       _labelText = label,
       _bodyPaint = Paint()..color = colorFor(view.def.id, view.def.color),
       super(
         position: Vector2(
           view.position.x * tileSize,
           view.position.y * tileSize,
         ),
         size: Vector2.all(tileSize * 0.78),
         anchor: Anchor.center,
         priority: 10,
       ) {
    final side = size.x;
    _body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, side, side),
      Radius.circular(side * 0.2),
    );
    _center = Offset(side / 2, side / 2);
    _barrelPaint = Paint()
      ..strokeWidth = side * 0.12
      ..strokeCap = StrokeCap.round
      ..color = BattleColors.outline;
    _barrelEnd = Offset(side * 0.62, 0);
    // El sprite ocupa una casilla, centrado en el cuadrado.
    final tile = tileSize;
    _spriteRect = Rect.fromCenter(center: _center, width: tile, height: tile);
    add(
      _label = TextComponent(
        text: label,
        anchor: Anchor.center,
        position: Vector2.all(side / 2),
        textRenderer: TextPaint(
          style: TextStyle(
            color: const Color(0xFFFFFFFF),
            fontSize: side * 0.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
    refresh();
  }

  final GuardianView view;

  /// La animación ya cargada de un sprite (o `null`: no tiene o no cargó).
  final SpriteAnimation? Function(SpriteDef? sprite) animationFor;

  final bool _hasAim;
  final String _labelText;
  late final TextComponent _label;
  late final Rect _spriteRect;
  SpriteDef? _spriteDef;
  SpriteBody? _sprite;
  final Paint _bodyPaint;
  late final RRect _body;
  late final Offset _center;
  late final Paint _barrelPaint;
  late final Offset _barrelEnd;
  List<Offset> _pips = const [];

  /// Ángulo actual de la honda y el ángulo al que gira (hacia arriba al
  /// construirse).
  double _aim = -math.pi / 2;
  double _targetAim = -math.pi / 2;

  bool selected = false;

  int get guardianId => view.id;

  bool get hasSprite => _sprite != null;

  /// Vuelve a leer el nivel (después de mejorar o especializarse): sus
  /// puntos y, si cambió, su sprite.
  void refresh() {
    final spriteDef = view.def.spriteAt(
      level: view.level,
      branchId: view.branchId,
    );
    if (spriteDef != _spriteDef || (_sprite == null && spriteDef != null)) {
      _spriteDef = spriteDef;
      final animation = animationFor(spriteDef);
      _sprite = animation == null ? null : SpriteBody(animation);
      _label.text = _sprite == null ? _labelText : '';
    }

    final count = view.level;
    final side = size.x;
    const gap = 7.0;
    final start = side / 2 - (count - 1) * gap / 2;
    _pips = [for (var i = 0; i < count; i++) Offset(start + i * gap, side + 5)];
  }

  /// Gira la honda hacia [target] (píxeles del mundo).
  void aimAt(Vector2 target) {
    _targetAim = math.atan2(target.y - position.y, target.x - position.x);
  }

  @override
  void update(double dt) {
    _sprite?.update(dt);
    if (!_hasAim) return;
    // La diferencia más corta entre los dos ángulos, en (−π, π].
    var delta = (_targetAim - _aim) % (2 * math.pi);
    if (delta > math.pi) delta -= 2 * math.pi;
    final step = _turnSpeed * dt;
    _aim += delta.abs() <= step ? delta : step * delta.sign;
  }

  @override
  void render(Canvas canvas) {
    final sprite = _sprite;
    if (sprite != null) {
      sprite.render(canvas, _spriteRect);
      if (selected) canvas.drawRRect(_body, _selectedPaint);
    } else {
      canvas
        ..drawRRect(_body, _bodyPaint)
        ..drawRRect(_body, selected ? _selectedPaint : _outlinePaint);
    }
    for (final pip in _pips) {
      canvas.drawCircle(pip, 2.5, _pipPaint);
    }
    if (_hasAim) {
      canvas
        ..save()
        ..translate(_center.dx, _center.dy)
        ..rotate(_aim)
        ..drawLine(Offset.zero, _barrelEnd, _barrelPaint)
        ..restore();
    }
  }

  @override
  void onTapUp(TapUpEvent event) => game.onGuardianTapped?.call(view.id);
}

SpriteAnimation? _noAnimation(SpriteDef? sprite) => null;
