import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/abilities/split_on_death.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/abilities/summon.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/attacks/area_attack.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/attacks/projectile_attack.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/attacks/support_aura.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/effects/burn_effect.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/effects/slow_effect.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/effects/stun_effect.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/targeting/targeting_strategies.dart';
import 'package:guardianes_chacra/features/battle/domain/registry/behavior_registry.dart';
import 'package:guardianes_chacra/features/content/domain/behavior_spec.dart';
import 'package:guardianes_chacra/features/content/domain/pest_def.dart';

void main() {
  final registry = BehaviorRegistry.withDefaults();

  String errorOf(void Function() action) {
    try {
      action();
    } on BehaviorDataError catch (error) {
      return error.message;
    }
    fail('No lanzó BehaviorDataError');
  }

  const projectile = {
    'damage': 6,
    'damageType': 'physical',
    'cooldown': 0.8,
    'projectileSpeed': 12,
  };

  /// [projectile] con [key] reemplazado (un mapa `const` no admite claves
  /// repetidas, así que no sirve `{...projectile, key: value}`).
  Map<String, Object?> projectileWith(String key, Object value) =>
      Map.of(projectile)..[key] = value;

  test('crea un efecto a partir de su tipo y sus parámetros', () {
    final effect = registry.createEffect(
      const BehaviorSpec('slow', {'factor': 0.6, 'duration': 2}),
    );

    expect(
      effect,
      isA<SlowEffect>()
          .having((slow) => slow.factor, 'factor', 0.6)
          .having((slow) => slow.durationTicks, 'durationTicks', 60),
    );
  });

  test('crea los efectos anidados de un ataque', () {
    final attack = registry.createGuardianBehavior(
      const BehaviorSpec('projectile', {
        ...projectile,
        'bonusAgainst': {'flying': 2},
        'onHit': [
          {'type': 'burn', 'damagePerSecond': 3, 'duration': 1.5},
        ],
      }),
    );

    final shot = (attack as ProjectileAttack).shot;
    expect(shot.hit.bonusAgainst, {PestTag.flying: 2});
    expect(
      shot.onHit.single,
      isA<BurnEffect>()
          .having((burn) => burn.damagePerSecond, 'damagePerSecond', 3)
          .having((burn) => burn.durationTicks, 'durationTicks', 45),
    );
  });

  test('trae registrados todos los tipos de serie', () {
    expect(registry.targeting('first'), isA<FirstTargeting>());
    expect(registry.targeting('last'), isA<LastTargeting>());
    expect(registry.targeting('strongest'), isA<StrongestTargeting>());
    expect(registry.targeting('closest'), isA<ClosestTargeting>());

    expect(
      registry.createGuardianBehavior(
        const BehaviorSpec('projectile', projectile),
      ),
      isA<ProjectileAttack>(),
    );
    expect(
      registry.createGuardianBehavior(
        const BehaviorSpec('area', {
          'damage': 2,
          'damageType': 'fire',
          'cooldown': 1,
        }),
      ),
      isA<AreaAttack>(),
    );
    expect(
      registry.createGuardianBehavior(
        const BehaviorSpec('support_aura', {'attackSpeedBonus': 0.25}),
      ),
      isA<SupportAura>(),
    );
    expect(
      registry.createEffect(const BehaviorSpec('stun', {'duration': 0.5})),
      isA<StunEffect>(),
    );
    expect(
      registry.createAbility(
        const BehaviorSpec('split_on_death', {'pest': 'granizo', 'count': 3}),
      ),
      isA<SplitOnDeath>(),
    );
    expect(
      registry.createAbility(
        const BehaviorSpec('summon', {
          'pest': 'gorgojo',
          'count': 2,
          'interval': 4,
        }),
      ),
      isA<Summon>(),
    );
  });

  group('tipos desconocidos', () {
    test('un efecto desconocido lista los disponibles', () {
      expect(
        errorOf(() => registry.createEffect(const BehaviorSpec('freeze'))),
        'Tipo de efecto desconocido: "freeze". '
        'Disponibles: burn, slow, stun.',
      );
    });

    test('una estrategia de apuntado desconocida lista las disponibles', () {
      expect(registry.hasTargeting('random'), isFalse);
      expect(
        errorOf(() => registry.targeting('random')),
        'Estrategia de apuntado desconocida: "random". '
        'Disponibles: closest, first, last, strongest.',
      );
    });
  });

  test('no se puede registrar dos veces el mismo tipo', () {
    expect(
      () => registry.registerEffect('slow', SlowEffect.fromParams),
      throwsStateError,
    );
  });

  group('parámetros inválidos', () {
    final cases = <(String, Object Function(), String)>[
      (
        'falta uno obligatorio',
        () =>
            registry.createEffect(const BehaviorSpec('slow', {'duration': 2})),
        'slow: falta "factor"',
      ),
      (
        'no es un número',
        () => registry.createEffect(
          const BehaviorSpec('slow', {'factor': 'mucho', 'duration': 2}),
        ),
        'slow: "factor" debe ser un número',
      ),
      (
        'fuera de rango',
        () => registry.createEffect(
          const BehaviorSpec('slow', {'factor': 1.5, 'duration': 2}),
        ),
        'slow: "factor" debe estar entre 0 y 1',
      ),
      (
        'no es mayor que 0',
        () => registry.createGuardianBehavior(
          BehaviorSpec('projectile', projectileWith('projectileSpeed', 0)),
        ),
        'projectile: "projectileSpeed" debe ser mayor que 0',
      ),
      (
        'tipo de daño desconocido',
        () => registry.createGuardianBehavior(
          BehaviorSpec('projectile', projectileWith('damageType', 'hielo')),
        ),
        'projectile: "damageType" debe ser uno de: physical, fire',
      ),
      (
        'etiqueta desconocida',
        () => registry.createGuardianBehavior(
          const BehaviorSpec('projectile', {
            ...projectile,
            'bonusAgainst': {'acuatico': 2},
          }),
        ),
        'projectile: "bonusAgainst" tiene una etiqueta desconocida '
            '"acuatico" (válidas: ground, flying)',
      ),
      (
        'efectos que no son una lista',
        () => registry.createGuardianBehavior(
          const BehaviorSpec('projectile', {...projectile, 'onHit': 'slow'}),
        ),
        'projectile: "onHit" debe ser una lista',
      ),
      (
        'efecto anidado sin tipo',
        () => registry.createGuardianBehavior(
          const BehaviorSpec('projectile', {
            ...projectile,
            'onHit': [
              {'factor': 0.5},
            ],
          }),
        ),
        'projectile: cada elemento de "onHit" necesita "type"',
      ),
      (
        'efecto anidado desconocido',
        () => registry.createGuardianBehavior(
          const BehaviorSpec('projectile', {
            ...projectile,
            'onHit': [
              {'type': 'freeze'},
            ],
          }),
        ),
        'projectile: "onHit": Tipo de efecto desconocido: "freeze". '
            'Disponibles: burn, slow, stun.',
      ),
      (
        'no es un entero',
        () => registry.createAbility(
          const BehaviorSpec('split_on_death', {'pest': 'x', 'count': 2.5}),
        ),
        'split_on_death: "count" debe ser un entero',
      ),
      (
        'entero por debajo del mínimo',
        () => registry.createAbility(
          const BehaviorSpec('split_on_death', {'pest': 'x', 'count': 0}),
        ),
        'split_on_death: "count" debe ser al menos 1',
      ),
      (
        'no es un texto',
        () => registry.createAbility(
          const BehaviorSpec('summon', {'pest': 3, 'count': 1, 'interval': 2}),
        ),
        'summon: "pest" debe ser un texto',
      ),
    ];

    for (final (name, create, message) in cases) {
      test(name, () => expect(errorOf(create), message));
    }
  });
}
