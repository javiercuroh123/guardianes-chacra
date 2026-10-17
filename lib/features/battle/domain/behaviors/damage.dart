import 'dart:math' as math;

import 'package:guardianes_chacra/features/content/domain/battle_rules.dart';
import 'package:guardianes_chacra/features/content/domain/pest_def.dart';
import 'package:meta/meta.dart';

/// Un golpe antes de aplicar las defensas de la plaga.
@immutable
class Hit {
  const new({
    required this.amount,
    required this.type,
    this.bonusAgainst = const {},
  });

  final double amount;
  final DamageType type;

  /// Multiplicador contra plagas con cierta etiqueta (por ejemplo, el
  /// Cóndor hace ×2 a los voladores).
  final Map<PestTag, double> bonusAgainst;
}

/// Daño que recibe [target] por [hit]:
///
/// 1. Se multiplica por la resistencia de la plaga a ese tipo de daño y por
///    el bonus del golpe contra sus etiquetas.
/// 2. Si es físico, se resta la armadura, pero siempre pasa al menos
///    `minDamageFraction` del daño (si no, una plaga muy acorazada sería
///    invencible para los guardianes físicos). El fuego ignora la armadura.
double damageDealt(Hit hit, PestDef target, BattleRules rules) {
  var damage = hit.amount * (target.resistances[hit.type] ?? 1);
  for (final tag in target.tags) {
    damage *= hit.bonusAgainst[tag] ?? 1;
  }
  if (hit.type == DamageType.physical) {
    damage = math.max(damage - target.armor, damage * rules.minDamageFraction);
  }
  return damage;
}
