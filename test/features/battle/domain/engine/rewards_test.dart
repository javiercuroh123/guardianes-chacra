import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/simulation.dart';
import 'package:guardianes_chacra/features/battle/domain/events/sim_events.dart';
import 'package:guardianes_chacra/features/content/domain/level_def.dart';

import '../../../../helpers/battle_fixtures.dart';

/// Las recompensas de los anuncios dentro de la simulación: empezar con
/// maíz extra y seguir una vez después de perder.
void main() {
  Simulation simulationOf(LevelDef level, {int extraCorn = 0}) => Simulation(
    level: level,
    pests: pestCatalog,
    guardians: guardianCatalog,
    rules: testRules,
    seed: 1,
    extraCorn: extraCorn,
  );

  void stepUntil(Simulation simulation, bool Function() done) {
    for (var i = 0; i < 3000 && !done(); i++) {
      simulation.step();
    }
    expect(done(), isTrue, reason: 'no llegó en 3000 ticks');
  }

  test('el maíz extra se suma al inicial', () {
    final simulation = simulationOf(
      testLevel(waves: [testWave('gorgojo')], corn: 80),
      extraCorn: 50,
    );

    expect(simulation.corn, 130);
  });

  group('revivir', () {
    // Una papa: el primer gorgojo hace perder mientras el segundo sigue en
    // camino. Otra oleada de tres llega 30 s después (ya revivida).
    Simulation lostWithOneLeft() {
      final simulation = simulationOf(
        testLevel(
          waves: [
            testWave('gorgojo', count: 2, interval: 2),
            testWave('gorgojo', count: 3, prepTime: 30),
          ],
          potatoes: 1,
        ),
      );
      stepUntil(simulation, () => simulation.status == BattleStatus.lost);
      return simulation;
    }

    test('mientras se juega no se puede', () {
      final simulation = simulationOf(testLevel(waves: [testWave('gorgojo')]));

      expect(simulation.canRevive, isFalse);
      expect(simulation.revive(5), isFalse);
      expect(simulation.revived, isFalse);
    });

    test('después de perder, sigue con las papas dadas y sin plagas', () {
      final simulation = lostWithOneLeft();
      expect(simulation.pests, isNotEmpty);
      final revived = <LevelRevived>[];
      final gone = <PestDefeated>[];
      simulation.events
        ..on<LevelRevived>(revived.add)
        ..on<PestDefeated>(gone.add);
      final corn = simulation.corn;

      expect(simulation.canRevive, isTrue);
      expect(simulation.revive(5), isTrue);

      expect(simulation.status, BattleStatus.playing);
      expect(simulation.potatoes, 5);
      expect(simulation.revived, isTrue);
      expect(revived.single.potatoes, 5);
      // El gorgojo que seguía en camino se fue, sin dar maíz.
      expect(simulation.pests, isEmpty);
      expect(gone.single.reward, 0);
      expect(simulation.corn, corn);

      // La oleada que faltaba llega igual: tres gorgojos, tres papas.
      stepUntil(simulation, () => simulation.status != BattleStatus.playing);
      expect(simulation.status, BattleStatus.won);
      expect(simulation.potatoes, 2);
    });

    test('solo una vez por partida', () {
      final simulation = lostWithOneLeft()..revive(1);

      stepUntil(simulation, () => simulation.status == BattleStatus.lost);

      expect(simulation.canRevive, isFalse);
      expect(simulation.revive(5), isFalse);
      expect(simulation.status, BattleStatus.lost);
    });

    test('sin papas no tiene sentido', () {
      final simulation = lostWithOneLeft();

      expect(simulation.revive(0), isFalse);
      expect(simulation.status, BattleStatus.lost);
    });
  });
}
