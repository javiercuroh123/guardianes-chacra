import 'package:guardianes_chacra/features/battle/domain/behaviors/attacks/guardian_behavior.dart';
import 'package:guardianes_chacra/features/battle/domain/registry/behavior_params.dart';
import 'package:guardianes_chacra/features/battle/domain/world/guardian.dart';

/// No ataca: los demás guardianes dentro de su alcance atacan más rápido
/// (el Pututu). Las auras no se suman: cada guardián recibe la mayor.
///
/// Datos: `attackSpeedBonus` (0,25 = +25 %).
final class SupportAura extends GuardianBehavior {
  new({required this.attackSpeedBonus});

  factory fromParams(BehaviorParams params) =>
      SupportAura(attackSpeedBonus: params.number('attackSpeedBonus', min: 0));

  final double attackSpeedBonus;

  @override
  double attackSpeedBonusFor(Guardian owner, Guardian other) {
    if (identical(owner, other)) return 0;
    final range = owner.range;
    final inRange =
        owner.position.distanceSquaredTo(other.position) <=
        range * range + 1e-9;
    return inRange ? attackSpeedBonus : 0;
  }
}
