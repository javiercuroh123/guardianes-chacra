import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/features/battle/domain/waves/wave_spawner.dart';
import 'package:guardianes_chacra/features/content/domain/level_def.dart';

void main() {
  // A 30 ticks por segundo: 1 s = 30, 0,5 s = 15, 0,2 s = 6.
  const waves = [
    WaveDef(
      prepTime: 1,
      reward: 10,
      groups: [
        SpawnGroupDef(
          pestId: 'gorgojo',
          count: 3,
          interval: 0.5,
          pathId: 'norte',
        ),
        SpawnGroupDef(
          pestId: 'polilla',
          count: 2,
          delay: 0.2,
          interval: 1,
          pathId: 'sur',
        ),
      ],
    ),
    WaveDef(
      prepTime: 0.5,
      reward: 10,
      groups: [SpawnGroupDef(pestId: 'langosta', count: 1, pathId: 'norte')],
    ),
  ];

  /// Ejecuta [ticks] ticks y anota en qué tick ocurrió cada cosa.
  ({Map<int, List<SpawnOrder>> spawns, Map<int, int> started}) run(
    WaveSpawner spawner,
    int ticks, {
    int firstTick = 1,
  }) {
    final spawns = <int, List<SpawnOrder>>{};
    final started = <int, int>{};
    for (var tick = firstTick; tick < firstTick + ticks; tick++) {
      final update = spawner.tick();
      if (update.spawns.isNotEmpty) spawns[tick] = update.spawns;
      if (update.startedWave case final wave?) started[tick] = wave;
    }
    return (spawns: spawns, started: started);
  }

  test('la primera oleada empieza al terminar su cuenta regresiva', () {
    final spawner = WaveSpawner(waves);

    expect(spawner.countdownTicks, 30);
    final result = run(spawner, 30);

    expect(result.started, {30: 0});
    expect(spawner.startedWaves, 1);
    expect(spawner.countdownTicks, isNull);
  });

  test('los grupos aparecen con su retraso e intervalo', () {
    final result = run(WaveSpawner(waves), 70);

    expect(result.spawns, {
      30: [(wave: 0, pestId: 'gorgojo', pathId: 'norte')],
      36: [(wave: 0, pestId: 'polilla', pathId: 'sur')],
      45: [(wave: 0, pestId: 'gorgojo', pathId: 'norte')],
      60: [(wave: 0, pestId: 'gorgojo', pathId: 'norte')],
      66: [(wave: 0, pestId: 'polilla', pathId: 'sur')],
    });
  });

  test('la siguiente oleada cuenta su preparación desde que terminó de '
      'aparecer la anterior', () {
    final spawner = WaveSpawner(waves);
    run(spawner, 65);
    expect(spawner.isFullySpawned(0), isFalse);

    run(spawner, 1, firstTick: 66);
    expect(spawner.isFullySpawned(0), isTrue);
    expect(spawner.countdownTicks, 15);

    final result = run(spawner, 20, firstTick: 67);
    expect(result.started, {81: 1});
    expect(result.spawns, {
      81: [(wave: 1, pestId: 'langosta', pathId: 'norte')],
    });
    expect(spawner.isFullySpawned(1), isTrue);
    expect(spawner.countdownTicks, isNull);
  });

  test('llamar la oleada antes de tiempo la empieza y devuelve los ticks '
      'que se saltó', () {
    final spawner = WaveSpawner(waves);
    run(spawner, 10);

    expect(spawner.callNextWave(), 20);
    expect(spawner.startedWaves, 1);
    expect(spawner.countdownTicks, isNull);

    // Sus plagas empiezan a aparecer en el tick siguiente.
    final result = run(spawner, 7, firstTick: 11);
    expect(result.spawns, {
      11: [(wave: 0, pestId: 'gorgojo', pathId: 'norte')],
      17: [(wave: 0, pestId: 'polilla', pathId: 'sur')],
    });
  });

  test('no se puede llamar una oleada si no hay cuenta regresiva', () {
    final spawner = WaveSpawner(waves);
    run(spawner, 40);

    // La primera oleada todavía está apareciendo.
    expect(spawner.callNextWave(), isNull);
    expect(spawner.startedWaves, 1);

    run(spawner, 100, firstTick: 41);
    // Ya no quedan oleadas.
    expect(spawner.startedWaves, 2);
    expect(spawner.callNextWave(), isNull);
  });

  test('un grupo con intervalo 0 aparece completo en el mismo tick', () {
    final spawner = WaveSpawner(const [
      WaveDef(
        prepTime: 0,
        reward: 0,
        groups: [SpawnGroupDef(pestId: 'langosta', count: 3, pathId: 'sur')],
      ),
    ]);

    final result = run(spawner, 1);

    expect(result.spawns[1], hasLength(3));
    expect(spawner.isFullySpawned(0), isTrue);
  });
}
