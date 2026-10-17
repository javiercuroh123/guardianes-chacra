import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/commands.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/simulation.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/simulation_cheats.dart';
import 'package:guardianes_chacra/features/battle/domain/events/sim_events.dart';
import 'package:guardianes_chacra/features/content/domain/level_def.dart';

import '../../../../helpers/battle_fixtures.dart';

void main() {
  Simulation simulationOf(LevelDef level, {SimulationCheats? cheats}) =>
      Simulation(
        level: level,
        pests: pestCatalog,
        guardians: guardianCatalog,
        rules: testRules,
        seed: 1,
        cheats: cheats,
      );

  void stepUntil(Simulation simulation, bool Function() done) {
    for (var i = 0; i < 3000 && !done(); i++) {
      simulation.step();
    }
    expect(done(), isTrue, reason: 'no llegó en 3000 ticks');
  }

  test('sin trucos, todo como siempre', () {
    final simulation = simulationOf(
      testLevel(waves: [testWave('gorgojo')], corn: 0),
    );

    expect(simulation.cheats.infiniteCorn, isFalse);
    expect(simulation.cheats.invincible, isFalse);
    expect(simulation.canAfford(1), isFalse);
  });

  test('con maíz infinito se construye sin gastar, aunque no alcance', () {
    final simulation =
        simulationOf(
            testLevel(waves: [testWave('gorgojo')], corn: 0),
            cheats: SimulationCheats()..infiniteCorn = true,
          )
          ..enqueue(const BuildGuardian(slotId: 'a', guardianType: 'hondero'))
          ..step();

    expect(simulation.guardians, hasLength(1));
    expect(simulation.corn, 0);
  });

  test('invencible: las plagas llegan a la collca sin comerse papas', () {
    final simulation = simulationOf(
      testLevel(waves: [testWave('gorgojo', count: 3)], potatoes: 2),
      cheats: SimulationCheats()..invincible = true,
    );
    final reached = <CollcaDamaged>[];
    simulation.events.on<CollcaDamaged>(reached.add);

    stepUntil(simulation, () => reached.length == 3);

    expect(simulation.potatoes, 2);
    expect(reached.map((event) => event.potatoesLost), [0, 0, 0]);
  });

  test(
    'saltar oleada quita las plagas sin dar maíz y empieza la siguiente',
    () {
      final simulation = simulationOf(
        testLevel(
          waves: [
            testWave('gorgojo', count: 5, reward: 0),
            testWave('gorgojo', prepTime: 30),
          ],
        ),
      );
      stepUntil(simulation, () => simulation.pests.length == 2);
      final cornBefore = simulation.corn;
      final onScreen = {for (final pest in simulation.pests) pest.id};

      simulation
        ..enqueue(const SkipWave())
        ..step();

      // Las dos de la oleada 1 se fueron (las 3 que faltaban ya no salen) y la
      // oleada 2 empezó sin esperar sus 30 s.
      expect(
        simulation.pests.where((pest) => onScreen.contains(pest.id)),
        isEmpty,
      );
      expect(simulation.startedWaves, 2);
      expect(simulation.corn, cornBefore);
    },
  );

  test('la prueba de estrés hace aparecer las plagas pedidas, de a una', () {
    final simulation = simulationOf(
      testLevel(waves: [testWave('gorgojo', prepTime: 60)]),
    );
    final spawned = <PestSpawned>[];
    simulation.events.on<PestSpawned>(spawned.add);

    simulation.enqueue(const StressTest(count: 10));
    for (var i = 0; i < 4; i++) {
      simulation.step();
    }
    // Una cada dos ticks: no todas a la vez.
    expect(spawned, hasLength(2));

    stepUntil(simulation, () => spawned.length == 10);
    expect(spawned.map((event) => event.pestType).toSet(), {'gorgojo'});
  });
}
