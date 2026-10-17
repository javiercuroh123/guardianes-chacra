import 'dart:math' as math;

import 'package:guardianes_chacra/features/battle/domain/behaviors/abilities/pest_ability.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/battle_context.dart';
import 'package:guardianes_chacra/features/battle/domain/registry/behavior_params.dart';
import 'package:guardianes_chacra/features/battle/domain/world/pest.dart';

/// Al ser derrotada se divide en [count] plagas de tipo [pestId] (el
/// Granizo). Aparecen donde murió, escalonadas [spacing] casillas hacia
/// atrás en el camino, y cuentan para la misma oleada.
///
/// Datos: `pest`, `count` y, opcional, `spacing` (0,3 por defecto).
final class SplitOnDeath extends PestAbility {
  new({required this.pestId, required this.count, this.spacing = 0.3});

  factory fromParams(BehaviorParams params) => SplitOnDeath(
    pestId: params.string('pest'),
    count: params.integer('count', min: 1),
    spacing: params.numberOr('spacing', 0.3, min: 0),
  );

  final String pestId;
  final int count;
  final double spacing;

  @override
  Iterable<String> get spawnsPests => [pestId];

  @override
  void onDeath(Pest pest, BattleContext context) {
    for (var i = 0; i < count; i++) {
      context.spawnPest(
        pestId,
        from: pest,
        distance: math.max(0, pest.distance - i * spacing),
      );
    }
  }
}
