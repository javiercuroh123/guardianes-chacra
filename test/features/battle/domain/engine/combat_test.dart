import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/core/math/vec2.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/attacks/guardian_behavior.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/damage.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/battle_context.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/commands.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/simulation.dart';
import 'package:guardianes_chacra/features/battle/domain/events/sim_events.dart';
import 'package:guardianes_chacra/features/battle/domain/registry/behavior_registry.dart';
import 'package:guardianes_chacra/features/battle/domain/world/guardian.dart';
import 'package:guardianes_chacra/features/content/domain/behavior_spec.dart';
import 'package:guardianes_chacra/features/content/domain/guardian_def.dart';
import 'package:guardianes_chacra/features/content/domain/level_def.dart';
import 'package:guardianes_chacra/features/content/domain/pest_def.dart';

import '../../../../helpers/battle_fixtures.dart';

// Recordatorio: 30 ticks por segundo. Los guardianes se construyen con
// comandos en el tick 1; las plagas de una oleada con prepTime 0 aparecen
// al final del tick 1, así que el primer ataque posible es en el tick 2.

const _granizo = PestDef(
  id: 'granizo',
  maxHealth: 5,
  speed: 1,
  cornReward: 2,
  potatoDamage: 1,
  tags: {PestTag.ground},
  abilities: [
    BehaviorSpec('split_on_death', {
      'pest': 'granizo_chico',
      'count': 3,
      'spacing': 0.3,
    }),
  ],
);

const _granizoChico = PestDef(
  id: 'granizo_chico',
  maxHealth: 1,
  speed: 1,
  cornReward: 1,
  potatoDamage: 1,
  tags: {PestTag.ground},
);

const _rey = PestDef(
  id: 'rey',
  maxHealth: 1000,
  speed: 0.5,
  cornReward: 50,
  potatoDamage: 5,
  tags: {PestTag.ground},
  abilities: [
    BehaviorSpec('summon', {'pest': 'gorgojo', 'count': 2, 'interval': 2}),
  ],
);

final Map<String, PestDef> _pests = {
  ...pestCatalog,
  'granizo': _granizo,
  'granizo_chico': _granizoChico,
  'rey': _rey,
};

GuardianDef _guardian(
  String id, {
  required double range,
  required Set<PestTag> targets,
  required List<BehaviorSpec> behaviors,
}) => GuardianDef(
  id: id,
  levels: [
    GuardianLevelDef(
      cost: 10,
      range: range,
      targets: targets,
      behaviors: behaviors,
    ),
  ],
);

/// Fuego en área cada 1 s: 2 de daño y quemadura de 3/s durante 1 s.
final GuardianDef _tullpa = _guardian(
  'tullpa',
  range: 2,
  targets: {PestTag.ground},
  behaviors: const [
    BehaviorSpec('area', {
      'damage': 2,
      'damageType': 'fire',
      'cooldown': 1,
      'onHit': [
        {'type': 'burn', 'damagePerSecond': 3, 'duration': 1},
      ],
    }),
  ],
);

/// Escupitajo con área de 1 casilla que ralentiza a la mitad durante 2 s.
final GuardianDef _llama = _guardian(
  'llama',
  range: 4,
  targets: {PestTag.ground, PestTag.flying},
  behaviors: const [
    BehaviorSpec('projectile', {
      'damage': 1,
      'damageType': 'physical',
      'cooldown': 1,
      'projectileSpeed': 30,
      'splashRadius': 1,
      'onHit': [
        {'type': 'slow', 'factor': 0.5, 'duration': 2},
      ],
    }),
  ],
);

GuardianDef _pututu(String id, double bonus) => _guardian(
  id,
  range: 2,
  targets: const {},
  behaviors: [
    BehaviorSpec('support_aura', {'attackSpeedBonus': bonus}),
  ],
);

/// Dispara 1 de daño cada 1 s a cualquier plaga de tierra del mapa.
final GuardianDef _contador = _guardian(
  'contador',
  range: 10,
  targets: {PestTag.ground},
  behaviors: [stone(1)],
);

final Map<String, GuardianDef> _guardians = {
  ...guardianCatalog,
  'tullpa': _tullpa,
  'llama': _llama,
  'pututu': _pututu('pututu', 0.5),
  'pututu_debil': _pututu('pututu_debil', 0.3),
  'contador': _contador,
};

Simulation _simulation(LevelDef level, {BehaviorRegistry? registry}) =>
    Simulation(
      level: level,
      pests: _pests,
      guardians: _guardians,
      rules: testRules,
      seed: 7,
      registry: registry,
    );

List<SimEvent> _record(Simulation simulation) {
  final events = <SimEvent>[];
  simulation.events.on<SimEvent>(events.add);
  return events;
}

void _stepUntil(Simulation simulation, int tick) {
  while (simulation.tick < tick && simulation.status == BattleStatus.playing) {
    simulation.step();
  }
}

/// Blancos quietos, cada uno al inicio de su propio camino en [positions].
LevelDef _targetPractice(List<Vec2> positions, List<BuildSlotDef> slots) =>
    testLevel(
      corn: 1000,
      slots: slots,
      paths: [
        for (final (index, at) in positions.indexed)
          PathDef(id: 'p$index', points: [at, Vec2(at.x, at.y + 10)]),
      ],
      waves: [
        WaveDef(
          prepTime: 0,
          reward: 0,
          groups: [
            for (var index = 0; index < positions.length; index++)
              SpawnGroupDef(pestId: 'blanco', count: 1, pathId: 'p$index'),
          ],
        ),
      ],
    );

BuildGuardian _build(String slotId, String type) =>
    BuildGuardian(slotId: slotId, guardianType: type);

/// Un ataque inventado en el test: elimina al instante a todo lo que está
/// a su alcance. Demuestra que un tipo nuevo se agrega sin tocar el motor.
final class _Rayo extends GuardianBehavior {
  @override
  void act(Guardian owner, BattleContext context) {
    for (final pest in context.targetsFor(owner)) {
      context.hit(pest, const Hit(amount: 1000, type: DamageType.fire));
    }
  }
}

void main() {
  test('un Hondero derrota a los gorgojos, gana su maíz y la oleada se '
      'completa', () {
    final simulation = _simulation(
      testLevel(waves: [testWave('gorgojo', count: 2)]),
    )..enqueue(_build('a', 'hondero'));
    final events = _record(simulation);

    _stepUntil(simulation, 1000);

    expect(simulation.status, BattleStatus.won);
    expect(simulation.potatoes, 10);
    expect(events.whereType<CollcaDamaged>(), isEmpty);
    expect(events.whereType<PestDefeated>().map((event) => event.reward), [
      5,
      5,
    ]);
    // 100 − 50 (hondero) + 5 + 5 (gorgojos) + 10 (oleada).
    expect(simulation.corn, 70);
  });

  group('etiquetas', () {
    for (final (pestId, shouldAttack) in [
      ('polilla', false),
      ('gorgojo', true),
    ]) {
      test('la Tullpa (solo tierra) ${shouldAttack ? 'sí' : 'no'} ataca a '
          '$pestId', () {
        final simulation = _simulation(
          testLevel(corn: 1000, waves: [testWave(pestId)]),
        )..enqueue(_build('a', 'tullpa'));
        final events = _record(simulation);

        _stepUntil(simulation, 1000);

        expect(events.whereType<AreaPulsed>().isNotEmpty, shouldAttack);
      });
    }
  });

  test('el área golpea a todas las plagas atacables a su alcance y la '
      'quemadura hace daño cada tick', () {
    // Tullpa en (0,5; 1) con alcance 2: alcanza a los blancos en (0, 0) y
    // (1, 0), pero no al de (5, 0).
    final simulation = _simulation(
      _targetPractice(
        const [Vec2(0, 0), Vec2(1, 0), Vec2(5, 0)],
        const [BuildSlotDef(id: 't', position: Vec2(0.5, 1))],
      ),
    )..enqueue(_build('t', 'tullpa'));
    final events = _record(simulation);
    double health(int id) =>
        simulation.pests.firstWhere((pest) => pest.id == id).health;

    _stepUntil(simulation, 2);
    expect(events.where((event) => event.tick == 2), [
      const AreaPulsed(2, guardianId: 1),
      const PestDamaged(2, pestId: 1, amount: 2, damageType: DamageType.fire),
      const PestDamaged(2, pestId: 2, amount: 2, damageType: DamageType.fire),
    ]);
    expect(simulation.pests.first.activeEffects, ['burn']);

    // Quemadura de 3/s = 0,1 por tick durante 30 ticks (del 3 al 32).
    _stepUntil(simulation, 31);
    expect(health(1), closeTo(100 - 2 - 2.9, 1e-9));
    expect(health(2), closeTo(100 - 2 - 2.9, 1e-9));
    expect(health(3), 100);

    // En el tick 32 termina la quemadura y llega el segundo pulso.
    _stepUntil(simulation, 32);
    expect(health(1), closeTo(100 - 2 - 3 - 2, 1e-9));
  });

  test('el escupitajo con área ralentiza a todas las plagas cerca del '
      'impacto', () {
    // La Llama en (0, 2) apunta al blanco 1 en (0, 0); el proyectil
    // (1 casilla por tick) sale en el tick 2 y llega en el 4.
    final simulation = _simulation(
      _targetPractice(
        const [Vec2(0, 0), Vec2(0.6, 0), Vec2(3, 0)],
        const [BuildSlotDef(id: 'l', position: Vec2(0, 2))],
      ),
    )..enqueue(_build('l', 'llama'));
    final events = _record(simulation);

    _stepUntil(simulation, 4);

    expect(
      events.whereType<ProjectileImpacted>().single,
      const ProjectileImpacted(4, projectileId: 1, position: Vec2(0, 0)),
    );
    final [near, alsoNear, far] = simulation.pests;
    expect(near.health, 99);
    expect(alsoNear.health, 99);
    expect(far.health, 100);
    expect(near.activeEffects, ['slow']);
    expect(alsoNear.activeEffects, ['slow']);
    expect(far.activeEffects, isEmpty);
  });

  test('el Pututu acelera solo a los guardianes a su alcance, y las auras '
      'no se suman', () {
    // Pututu (+50 %) en (0, 0) y Pututu débil (+30 %) en (1, 1), ambos con
    // alcance 2. El contador cercano está en (1, 0); el lejano, en (5, 0).
    final simulation = _simulation(
      _targetPractice(
        const [Vec2(2, 3)],
        const [
          BuildSlotDef(id: 'p1', position: Vec2(0, 0)),
          BuildSlotDef(id: 'cerca', position: Vec2(1, 0)),
          BuildSlotDef(id: 'lejos', position: Vec2(5, 0)),
          BuildSlotDef(id: 'p2', position: Vec2(1, 1)),
        ],
      ),
    );
    [
      _build('p1', 'pututu'),
      _build('cerca', 'contador'),
      _build('lejos', 'contador'),
      _build('p2', 'pututu_debil'),
    ].forEach(simulation.enqueue);
    final events = _record(simulation);

    _stepUntil(simulation, 61);

    final [_, near, far, _] = simulation.guardians;
    expect(near.attackSpeedMultiplier, 1.5);
    expect(far.attackSpeedMultiplier, 1);
    int shotsBy(GuardianView guardian) => events
        .whereType<GuardianFired>()
        .where((event) => event.guardianId == guardian.id)
        .length;
    // Del tick 2 al 61: el cercano dispara cada 20 ticks (2, 22, 42) y el
    // lejano cada 30 (2, 32).
    expect(shotsBy(near), 3);
    expect(shotsBy(far), 2);
  });

  group('Granizo', () {
    test('se divide al morir y sus trozos cuentan para la oleada', () {
      final simulation = _simulation(
        testLevel(waves: [testWave('granizo')]),
      )..enqueue(_build('a', 'hondero'));
      final events = _record(simulation);

      for (var i = 0; i < 1000 && events.whereType<PestDefeated>().isEmpty;
          i++) {
        simulation.step();
      }

      final death = events.whereType<PestDefeated>().single;
      expect(death.pestType, 'granizo');
      expect(
        events.whereType<PestSpawned>().where(
          (event) => event.pestType == 'granizo_chico',
        ),
        hasLength(3),
      );
      final pieces = simulation.pests;
      expect(
        pieces.map((pest) => pest.def.id),
        List.filled(3, 'granizo_chico'),
      );
      // Aparecen donde murió, escalonados 0,3 casillas hacia atrás.
      expect(pieces[0].distance, greaterThan(2));
      expect(pieces[0].distance - pieces[1].distance, closeTo(0.3, 1e-9));
      expect(pieces[1].distance - pieces[2].distance, closeTo(0.3, 1e-9));
      expect(events.whereType<WaveCompleted>(), isEmpty);

      _stepUntil(simulation, 2000);

      expect(simulation.status, BattleStatus.won);
      expect(events.whereType<PestDefeated>(), hasLength(4));
      // 100 − 50 + 2 (granizo) + 3 × 1 (trozos) + 10 (oleada).
      expect(simulation.corn, 65);
    });

    test('no se divide si llega a la collca', () {
      final simulation = _simulation(testLevel(waves: [testWave('granizo')]));
      final events = _record(simulation);

      _stepUntil(simulation, 2000);

      expect(events.whereType<CollcaDamaged>(), hasLength(1));
      expect(
        events.whereType<PestSpawned>().map((event) => event.pestType),
        ['granizo'],
      );
      expect(simulation.status, BattleStatus.won);
    });
  });

  test('el Rey Gorgojo invoca gorgojos cada 2 s detrás de él', () {
    // Aparece en el tick 30; invoca en los ticks 90 y 150.
    final simulation = _simulation(testLevel(waves: [testWave('rey')]));
    final events = _record(simulation);

    // Justo al invocarlos están detrás de él (después, más rápidos, lo
    // adelantan).
    _stepUntil(simulation, 90);
    final [rey, ...summonedNow] = simulation.pests;
    expect(summonedNow, hasLength(2));
    expect(
      summonedNow.every((pest) => pest.distance < rey.distance),
      isTrue,
    );

    _stepUntil(simulation, 160);
    final summoned = events.whereType<PestSpawned>().where(
      (event) => event.pestType == 'gorgojo',
    );
    expect(summoned.map((event) => event.tick), [90, 90, 150, 150]);
  });

  test('un tipo de ataque nuevo se registra y funciona sin tocar el '
      'motor', () {
    final registry = BehaviorRegistry.withDefaults()
      ..registerGuardianBehavior('rayo', (_) => _Rayo());
    final rayo = _guardian(
      'rayo',
      range: 3,
      targets: {PestTag.ground},
      behaviors: const [BehaviorSpec('rayo')],
    );
    final simulation = Simulation(
      level: testLevel(waves: [testWave('gorgojo')]),
      pests: _pests,
      guardians: {'rayo': rayo},
      rules: testRules,
      seed: 7,
      registry: registry,
    )..enqueue(_build('a', 'rayo'));
    final events = _record(simulation);

    _stepUntil(simulation, 1000);

    expect(events.whereType<PestDefeated>(), hasLength(1));
    expect(events.whereType<GuardianFired>(), isEmpty);
    expect(simulation.status, BattleStatus.won);
  });

  test('la misma semilla y los mismos comandos dan el mismo combate', () {
    final level = testLevel(
      corn: 1000,
      potatoes: 30,
      waves: [
        testWave('gorgojo', count: 6, interval: 0.4),
        testWave('granizo', count: 3, interval: 0.7, prepTime: 3),
        testWave('polilla', count: 4, interval: 0.3, prepTime: 2),
      ],
    );

    List<SimEvent> play() {
      final simulation = _simulation(level)
        ..enqueue(_build('a', 'hondero'))
        ..enqueue(_build('b', 'llama'));
      final events = _record(simulation);
      for (var i = 0; i < 3000 && simulation.status == BattleStatus.playing;
          i++) {
        if (simulation.tick == 100) {
          simulation.enqueue(const SetTargeting(1, strategy: 'strongest'));
        }
        simulation.step();
      }
      return events;
    }

    final first = play();

    expect(first.whereType<PestDefeated>(), isNotEmpty);
    expect(play(), first);
  });
}
