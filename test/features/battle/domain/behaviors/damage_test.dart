import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/damage.dart';
import 'package:guardianes_chacra/features/content/domain/battle_rules.dart';
import 'package:guardianes_chacra/features/content/domain/pest_def.dart';

void main() {
  const rules = BattleRules(
    sellRefundRate: 0.7,
    minDamageFraction: 0.2,
    twoStarsFraction: 0.5,
    threeStarsFraction: 0.9,
  );

  PestDef pest({
    double armor = 0,
    Map<DamageType, double> resistances = const {},
    Set<PestTag> tags = const {PestTag.ground},
  }) => PestDef(
    id: 'prueba',
    maxHealth: 100,
    speed: 1,
    cornReward: 1,
    potatoDamage: 1,
    tags: tags,
    armor: armor,
    resistances: resistances,
  );

  const physical6 = Hit(amount: 6, type: DamageType.physical);
  const fire6 = Hit(amount: 6, type: DamageType.fire);

  test('sin armadura ni resistencias, el daño es el del golpe', () {
    expect(damageDealt(physical6, pest(), rules), 6);
  });

  test('la armadura se resta del daño físico', () {
    expect(damageDealt(physical6, pest(armor: 4), rules), 2);
  });

  test('siempre atraviesa la fracción mínima del daño físico', () {
    // 6 − 10 sería negativo: pasa el 20 % de 6.
    expect(damageDealt(physical6, pest(armor: 10), rules), closeTo(1.2, 1e-9));
  });

  test('el fuego ignora la armadura', () {
    expect(damageDealt(fire6, pest(armor: 4), rules), 6);
  });

  test('la resistencia multiplica el daño de su tipo', () {
    final helada = pest(resistances: {DamageType.physical: 0.5});
    final escarabajo = pest(armor: 4, resistances: {DamageType.fire: 1.5});

    expect(damageDealt(physical6, helada, rules), 3);
    expect(damageDealt(fire6, helada, rules), 6);
    expect(damageDealt(fire6, escarabajo, rules), 9);
  });

  test('la resistencia se aplica antes de restar la armadura', () {
    // 6 × 2 = 12, menos 4 de armadura = 8 (y no 6 − 4 = 2, × 2 = 4).
    final weak = pest(armor: 4, resistances: {DamageType.physical: 2});

    expect(damageDealt(physical6, weak, rules), 8);
  });

  test('el bonus contra una etiqueta solo afecta a esas plagas', () {
    const condor = Hit(
      amount: 6,
      type: DamageType.physical,
      bonusAgainst: {PestTag.flying: 2},
    );

    expect(damageDealt(condor, pest(tags: {PestTag.flying}), rules), 12);
    expect(damageDealt(condor, pest(), rules), 6);
  });
}
