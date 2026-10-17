import 'dart:math' as math;

import 'package:guardianes_chacra/features/battle/domain/behaviors/abilities/pest_ability.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/battle_context.dart';
import 'package:guardianes_chacra/features/battle/domain/registry/behavior_params.dart';
import 'package:guardianes_chacra/features/battle/domain/world/pest.dart';

/// Cada [intervalTicks] invoca [count] plagas de tipo [pestId] justo
/// detrás de ella (el Rey Gorgojo). Cuentan para la misma oleada. La
/// primera invocación llega un intervalo después de aparecer.
///
/// Datos: `pest`, `count`, `interval` (s) y, opcional, `spacing`.
final class Summon extends PestAbility {
  new({
    required this.pestId,
    required this.count,
    required int intervalTicks,
    this.spacing = 0.3,
  }) : intervalTicks = math.max(1, intervalTicks),
       _ticksLeft = math.max(1, intervalTicks);

  factory fromParams(BehaviorParams params) => Summon(
    pestId: params.string('pest'),
    count: params.integer('count', min: 1),
    intervalTicks: params.ticks('interval'),
    spacing: params.numberOr('spacing', 0.3, min: 0),
  );

  final String pestId;
  final int count;
  final int intervalTicks;
  final double spacing;

  int _ticksLeft;

  @override
  Iterable<String> get spawnsPests => [pestId];

  @override
  void onTick(Pest pest, BattleContext context) {
    _ticksLeft--;
    if (_ticksLeft > 0) return;
    _ticksLeft = intervalTicks;
    for (var i = 1; i <= count; i++) {
      context.spawnPest(
        pestId,
        from: pest,
        distance: math.max(0, pest.distance - i * spacing),
      );
    }
  }
}
