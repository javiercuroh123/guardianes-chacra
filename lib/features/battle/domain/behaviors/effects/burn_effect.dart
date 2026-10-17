import 'dart:math' as math;

import 'package:guardianes_chacra/features/battle/domain/behaviors/damage.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/effects/status_effect.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/battle_context.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/sim_time.dart';
import 'package:guardianes_chacra/features/battle/domain/registry/behavior_params.dart';
import 'package:guardianes_chacra/features/battle/domain/world/pest.dart';
import 'package:guardianes_chacra/features/content/domain/pest_def.dart';

/// Daño de fuego en el tiempo: [damagePerSecond] repartido en cada tick.
///
/// Acumulación: no se suman. Queda el mayor daño por segundo y la duración
/// se renueva (sin acortarse nunca).
///
/// Datos: `damagePerSecond` y `duration` (s).
final class BurnEffect extends StatusEffect {
  const new({required this.damagePerSecond, required this.durationTicks});

  factory fromParams(BehaviorParams params) => BurnEffect(
    damagePerSecond: params.number('damagePerSecond', min: 0),
    durationTicks: params.ticks('duration'),
  );

  final double damagePerSecond;

  @override
  final int durationTicks;

  @override
  String get type => 'burn';

  @override
  void onTick(Pest pest, BattleContext context) => context.hit(
    pest,
    Hit(amount: damagePerSecond / ticksPerSecond, type: DamageType.fire),
  );

  @override
  ActiveEffect mergeInto(ActiveEffect current) {
    final currentBurn = current.effect as BurnEffect;
    final stronger = damagePerSecond >= currentBurn.damagePerSecond
        ? this
        : currentBurn;
    return ActiveEffect(stronger, math.max(current.remaining, durationTicks));
  }
}
