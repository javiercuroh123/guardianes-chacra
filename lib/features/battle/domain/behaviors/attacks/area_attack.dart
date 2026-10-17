import 'package:guardianes_chacra/features/battle/domain/behaviors/attacks/cooldown.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/attacks/guardian_behavior.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/damage.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/effects/status_effect.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/battle_context.dart';
import 'package:guardianes_chacra/features/battle/domain/events/sim_events.dart';
import 'package:guardianes_chacra/features/battle/domain/registry/behavior_params.dart';
import 'package:guardianes_chacra/features/battle/domain/world/guardian.dart';

/// Golpea a la vez a todas las plagas atacables dentro del alcance (por
/// ejemplo, el fuego de la Tullpa). Solo se activa si hay alguna.
///
/// Datos: `damage`, `damageType`, `cooldown` (s) y, opcionales,
/// `bonusAgainst` y `onHit`.
final class AreaAttack extends GuardianBehavior {
  new({
    required this.hit,
    required int cooldownTicks,
    this.onHit = const [],
  }) : _cooldown = Cooldown(cooldownTicks);

  factory fromParams(BehaviorParams params) => AreaAttack(
    hit: Hit(
      amount: params.number('damage', min: 0),
      type: params.damageType('damageType'),
      bonusAgainst: params.tagMultipliers('bonusAgainst'),
    ),
    onHit: params.effects('onHit'),
    cooldownTicks: params.ticks('cooldown'),
  );

  final Hit hit;
  final List<StatusEffect> onHit;
  final Cooldown _cooldown;

  @override
  void act(Guardian owner, BattleContext context) {
    if (!_cooldown.advance(owner.attackSpeedMultiplier)) return;
    final targets = context.targetsFor(owner);
    if (targets.isEmpty) return;

    context.publish(AreaPulsed(context.tick, guardianId: owner.id));
    for (final pest in targets) {
      context.hit(pest, hit);
      for (final effect in onHit) {
        context.applyEffect(pest, effect);
      }
    }
    _cooldown.restart();
  }
}
