import 'package:guardianes_chacra/features/battle/domain/engine/battle_context.dart';
import 'package:guardianes_chacra/features/battle/domain/world/guardian.dart';

/// Un ataque o aura de un guardián. Un guardián combina uno o más. Cada
/// guardián recibe sus propias instancias, así que pueden guardar estado
/// (por ejemplo, el tiempo de recarga).
abstract class GuardianBehavior {
  /// Bonificación de velocidad de ataque (0,25 = +25 %) que [owner] da a
  /// [other]. Solo las auras devuelven algo distinto de 0.
  double attackSpeedBonusFor(Guardian owner, Guardian other) => 0;

  /// Se llama una vez por tick, en la fase de ataque.
  void act(Guardian owner, BattleContext context) {}
}
