import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:guardianes_chacra/features/battle/presentation/battle_game.dart';
import 'package:guardianes_chacra/features/battle/presentation/style/battle_colors.dart';

final Paint _selectedPaint = Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 3
  ..color = BattleColors.selection;

/// Un espacio de construcción: la zona tocable de una casilla. El dibujo
/// del espacio está en el mapa; aquí solo se resalta cuando se selecciona.
class SlotComponent extends PositionComponent
    with TapCallbacks, HasGameReference<BattleGame> {
  new({
    required this.slotId,
    required Vector2 position,
    required double tileSize,
  }) : super(
         position: position,
         size: Vector2.all(tileSize),
         anchor: Anchor.center,
         priority: 5,
       ) {
    _outline = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 2, tileSize - 4, tileSize - 4),
      Radius.circular(tileSize * 0.15),
    );
  }

  final String slotId;
  late final RRect _outline;
  bool selected = false;

  @override
  void render(Canvas canvas) {
    if (selected) canvas.drawRRect(_outline, _selectedPaint);
  }

  @override
  void onTapUp(TapUpEvent event) => game.onSlotTapped?.call(slotId);
}

/// Cubre todo el mapa por debajo de espacios y guardianes: recibe los
/// toques que no caen sobre ninguno de ellos (por ejemplo, para cerrar un
/// menú).
class GroundComponent extends PositionComponent
    with TapCallbacks, HasGameReference<BattleGame> {
  new({required Vector2 size}) : super(size: size, priority: 1);

  @override
  void onTapUp(TapUpEvent event) => game.onEmptyTapped?.call();
}
