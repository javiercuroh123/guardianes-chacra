import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/commands.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/simulation.dart';
import 'package:guardianes_chacra/features/battle/domain/events/sim_events.dart';
import 'package:guardianes_chacra/features/content/domain/level_def.dart';

import '../../../../helpers/battle_fixtures.dart';

// Recordatorio para leer las cuentas: 30 ticks por segundo. Con
// prepTime = 1 s, la primera oleada empieza (y su primera plaga aparece)
// en el tick 30; la plaga empieza a moverse en el tick 31.

Simulation _simulation(LevelDef level, {int seed = 1}) =>
    Simulation(level: level, pests: pestCatalog, seed: seed);

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

void main() {
  test('empieza con el maíz y las papas del nivel', () {
    final simulation = _simulation(testLevel(waves: [testWave('gorgojo')]));

    expect(simulation.tick, 0);
    expect(simulation.corn, 100);
    expect(simulation.potatoes, 10);
    expect(simulation.status, BattleStatus.playing);
    expect(simulation.totalWaves, 1);
    expect(simulation.nextWaveCountdownTicks, 30);
  });

  group('movimiento', () {
    // Camino de 10 casillas: el gorgojo (2 casillas/s) tarda 150 ticks y la
    // polilla (5 casillas/s), 60.
    for (final (pestId, arrivalTick) in [('gorgojo', 180), ('polilla', 90)]) {
      test('$pestId recorre el camino en el tiempo que da su velocidad', () {
        final simulation = _simulation(testLevel(waves: [testWave(pestId)]));
        final events = _record(simulation);

        _stepUntil(simulation, arrivalTick - 1);
        expect(simulation.pests, hasLength(1));
        expect(events.whereType<CollcaDamaged>(), isEmpty);

        simulation.step();
        expect(simulation.pests, isEmpty);
        expect(events.whereType<CollcaDamaged>().single.tick, arrivalTick);
      });
    }

    test('la posición se interpola sobre el camino según la distancia', () {
      final simulation = _simulation(testLevel(waves: [testWave('gorgojo')]));

      _stepUntil(simulation, 30);
      final pest = simulation.pests.single;
      expect(pest.distance, 0);

      // 75 ticks = 2,5 s a 2 casillas/s = 5 casillas: mitad del camino.
      _stepUntil(simulation, 105);
      expect(pest.distance, closeTo(5, 1e-9));
      expect(pest.position.x, closeTo(5, 1e-9));
      expect(pest.position.y, 0);
    });
  });

  test('una plaga que llega a la collca resta sus papas y desaparece', () {
    final simulation = _simulation(testLevel(waves: [testWave('polilla')]));
    final events = _record(simulation);

    _stepUntil(simulation, 90);

    expect(simulation.potatoes, 8);
    expect(simulation.pests, isEmpty);
    expect(
      events.whereType<CollcaDamaged>(),
      [const CollcaDamaged(90, pestId: 1, potatoesLost: 2, potatoesLeft: 8)],
    );
  });

  test('aparecer una plaga emite PestSpawned', () {
    final simulation = _simulation(testLevel(waves: [testWave('gorgojo')]));
    final events = _record(simulation);

    _stepUntil(simulation, 30);

    expect(events, [
      const WaveStarted(30, waveNumber: 1, calledEarly: false),
      const PestSpawned(30, pestId: 1, pestType: 'gorgojo', pathId: 'recto'),
    ]);
  });

  test('se pierde cuando las papas llegan a 0, sin bajar de 0', () {
    // Dos polillas (2 papas cada una) contra 3 papas. Llegan en los
    // ticks 90 y 120.
    final simulation = _simulation(
      testLevel(potatoes: 3, waves: [testWave('polilla', count: 2)]),
    );
    final events = _record(simulation);

    _stepUntil(simulation, 200);

    expect(simulation.status, BattleStatus.lost);
    expect(simulation.potatoes, 0);
    expect(simulation.tick, 120);
    expect(events.whereType<CollcaDamaged>().last.potatoesLost, 1);
    expect(events.last, const LevelLost(120));
    // Perder tiene prioridad: la oleada ya no cuenta como completada.
    expect(events.whereType<WaveCompleted>(), isEmpty);
    expect(events.whereType<LevelWon>(), isEmpty);
  });

  test('se gana al completar todas las oleadas con papas', () {
    // Oleada 1: dos gorgojos (ticks 30 y 60), llegan en 180 y 210.
    // Oleada 2: su cuenta empieza en 60 y dura 30 ticks; la polilla aparece
    // en 90 y llega en 150.
    final simulation = _simulation(
      testLevel(
        waves: [
          testWave('gorgojo', count: 2),
          testWave('polilla', reward: 15),
        ],
      ),
    );
    final events = _record(simulation);

    _stepUntil(simulation, 300);

    expect(simulation.status, BattleStatus.won);
    expect(simulation.tick, 210);
    expect(simulation.potatoes, 6);
    expect(simulation.corn, 125);
    expect(
      events.where(
        (event) =>
            event is WaveCompleted || event is CornChanged || event is LevelWon,
      ),
      [
        const WaveCompleted(150, waveNumber: 2, reward: 15),
        const CornChanged(150, delta: 15, total: 115),
        // La oleada 1 no se completa en 180: todavía queda un gorgojo.
        const WaveCompleted(210, waveNumber: 1, reward: 10),
        const CornChanged(210, delta: 10, total: 125),
        const LevelWon(210, potatoesLeft: 6),
      ],
    );
  });

  test('después de ganar o perder, step() ya no hace nada', () {
    final simulation = _simulation(testLevel(waves: [testWave('polilla')]));
    _stepUntil(simulation, 1000);
    expect(simulation.status, BattleStatus.won);
    final events = _record(simulation);

    simulation
      ..enqueue(const CallNextWave())
      ..step();

    expect(simulation.tick, 90);
    expect(events, isEmpty);
  });

  group('llamar la siguiente oleada', () {
    test('antes de tiempo da maíz por los segundos que se salta', () {
      // 10 s de preparación (300 ticks) a 2 de maíz por segundo = 20.
      final simulation = _simulation(
        testLevel(waves: [testWave('gorgojo', prepTime: 10)]),
      );
      final events = _record(simulation);
      expect(simulation.earlyCallBonus, 20);

      simulation.enqueue(const CallNextWave());
      // El comando se aplica en el siguiente tick, no antes.
      expect(simulation.startedWaves, 0);
      simulation.step();

      expect(simulation.startedWaves, 1);
      expect(simulation.corn, 120);
      expect(events, [
        const WaveStarted(1, waveNumber: 1, calledEarly: true),
        const CornChanged(1, delta: 20, total: 120),
        const PestSpawned(1, pestId: 1, pestType: 'gorgojo', pathId: 'recto'),
      ]);
    });

    test('la bonificación baja a medida que corre la cuenta regresiva', () {
      final simulation = _simulation(
        testLevel(waves: [testWave('gorgojo', prepTime: 10)]),
      );

      // Tras 4 s quedan 6 s: 12 de maíz.
      _stepUntil(simulation, 120);
      expect(simulation.nextWaveCountdownTicks, 180);
      expect(simulation.earlyCallBonus, 12);

      simulation
        ..enqueue(const CallNextWave())
        ..step();
      expect(simulation.corn, 112);
    });

    test('sin cuenta regresiva se rechaza el comando', () {
      // Tres gorgojos que aparecen en los ticks 30, 60 y 90.
      final simulation = _simulation(
        testLevel(waves: [testWave('gorgojo', count: 3)]),
      );
      _stepUntil(simulation, 40);
      final events = _record(simulation);
      expect(simulation.earlyCallBonus, 0);

      simulation
        ..enqueue(const CallNextWave())
        ..step();

      expect(events, [
        const CommandRejected(
          41,
          command: CallNextWave(),
          reason: RejectionReason.noWaveWaiting,
        ),
      ]);
      expect(simulation.corn, 100);
    });
  });

  test('la misma semilla y los mismos comandos dan la misma partida', () {
    final level = testLevel(
      potatoes: 20,
      waves: [
        testWave('gorgojo', count: 4, interval: 0.5),
        testWave('polilla', count: 3, prepTime: 5, interval: 0.3),
        testWave('gorgojo', count: 2, prepTime: 8),
      ],
    );

    ({List<SimEvent> events, int tick, int corn, int potatoes}) play() {
      final simulation = _simulation(level, seed: 2026);
      final events = _record(simulation);
      for (var i = 0; i < 2000 && simulation.status == BattleStatus.playing;
          i++) {
        // Llama las oleadas en ticks fijos (si no se puede, se rechaza).
        if (simulation.tick == 10 || simulation.tick == 200) {
          simulation.enqueue(const CallNextWave());
        }
        simulation.step();
      }
      return (
        events: events,
        tick: simulation.tick,
        corn: simulation.corn,
        potatoes: simulation.potatoes,
      );
    }

    final first = play();
    final second = play();

    expect(first.events, isNotEmpty);
    expect(second.events, first.events);
    expect(
      (second.tick, second.corn, second.potatoes),
      (first.tick, first.corn, first.potatoes),
    );
  });

  group('validación del nivel', () {
    test('rechaza una oleada con una plaga que no existe', () {
      final level = testLevel(waves: [testWave('escarabajo')]);

      expect(
        () => _simulation(level),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('escarabajo'),
          ),
        ),
      );
    });

    test('rechaza una oleada con un camino que no existe', () {
      final level = testLevel(
        waves: const [
          WaveDef(
            prepTime: 1,
            reward: 0,
            groups: [
              SpawnGroupDef(pestId: 'gorgojo', count: 1, pathId: 'lago'),
            ],
          ),
        ],
      );

      expect(
        () => _simulation(level),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('lago'),
          ),
        ),
      );
    });
  });
}
