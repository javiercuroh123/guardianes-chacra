import 'package:guardianes_chacra/features/battle/domain/behaviors/attacks/cooldown.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/attacks/guardian_behavior.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/damage.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/battle_context.dart';
import 'package:guardianes_chacra/features/battle/domain/registry/behavior_params.dart';
import 'package:guardianes_chacra/features/battle/domain/world/guardian.dart';
import 'package:guardianes_chacra/features/battle/domain/world/projectile.dart';

/// Lanza un proyectil a un objetivo elegido por la estrategia de apuntado
/// del guardián. Con `splashRadius` también daña alrededor del impacto.
///
/// Datos: `damage`, `damageType`, `cooldown` (s), `projectileSpeed`
/// (casillas/s) y, opcionales, `splashRadius`, `bonusAgainst` y `onHit`.
final class ProjectileAttack extends GuardianBehavior {
  new({required this.shot, required int cooldownTicks})
    : _cooldown = Cooldown(cooldownTicks);

  factory fromParams(BehaviorParams params) => ProjectileAttack(
    shot: ProjectileShot(
      hit: Hit(
        amount: params.number('damage', min: 0),
        type: params.damageType('damageType'),
        bonusAgainst: params.tagMultipliers('bonusAgainst'),
      ),
      speed: params.positive('projectileSpeed'),
      splashRadius: params.numberOr('splashRadius', 0, min: 0),
      onHit: params.effects('onHit'),
    ),
    cooldownTicks: params.ticks('cooldown'),
  );

  final ProjectileShot shot;
  final Cooldown _cooldown;

  @override
  void act(Guardian owner, BattleContext context) {
    if (!_cooldown.advance(owner.attackSpeedMultiplier)) return;
    final target = owner.targeting.choose(
      context.targetsFor(owner),
      owner.position,
    );
    // Sin objetivo se queda listo: dispara apenas entre alguien.
    if (target == null) return;
    context.launchProjectile(from: owner, target: target, shot: shot);
    _cooldown.restart();
  }
}
