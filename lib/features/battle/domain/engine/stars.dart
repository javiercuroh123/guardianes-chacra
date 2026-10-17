import 'package:guardianes_chacra/features/content/domain/battle_rules.dart';

/// Estrellas de una partida (0 si se perdió, de 1 a 3 si se ganó) según la
/// fracción de las papas iniciales que quedaron en la collca. Los umbrales
/// están en `rules.json`.
int starsFor({
  required int potatoesLeft,
  required int startingPotatoes,
  required BattleRules rules,
}) {
  if (potatoesLeft <= 0) return 0;
  // El margen evita que 18/20 = 0,8999999 quede por debajo de 0,9.
  final saved = potatoesLeft / startingPotatoes + 1e-9;
  if (saved >= rules.threeStarsFraction) return 3;
  if (saved >= rules.twoStarsFraction) return 2;
  return 1;
}
