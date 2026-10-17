import 'dart:collection';

import 'package:guardianes_chacra/core/events/event_bus.dart';
import 'package:guardianes_chacra/core/math/seeded_random.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/commands.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/sim_time.dart';
import 'package:guardianes_chacra/features/battle/domain/events/sim_events.dart';
import 'package:guardianes_chacra/features/battle/domain/waves/wave_spawner.dart';
import 'package:guardianes_chacra/features/battle/domain/world/path_track.dart';
import 'package:guardianes_chacra/features/battle/domain/world/pest.dart';
import 'package:guardianes_chacra/features/content/domain/level_def.dart';
import 'package:guardianes_chacra/features/content/domain/pest_def.dart';

enum BattleStatus { playing, won, lost }

/// La partida en Dart puro. No conoce Flame, ni el reloj real, ni la
/// pantalla: avanza exactamente un tick con cada [step] y publica en
/// [events] lo que ocurre.
///
/// Orden dentro de un tick: comandos del jugador → movimiento y llegadas a
/// la collca → derrota → nuevas plagas → oleadas completadas → victoria.
class Simulation {
  new({
    required LevelDef level,
    required Map<String, PestDef> pests,
    required int seed,
    EventBus<SimEvent>? events,
  }) : events = events ?? EventBus<SimEvent>(),
       random = SeededRandom(seed),
       _level = level,
       _pestDefs = Map.unmodifiable(pests),
       _tracks = {
         for (final path in level.paths) path.id: PathTrack(path.points),
       },
       _spawner = WaveSpawner(level.waves),
       _corn = level.startingCorn,
       _potatoes = level.startingPotatoes,
       _aliveByWave = List.filled(level.waves.length, 0),
       _completedWaves = List.filled(level.waves.length, false) {
    _validate();
  }

  final EventBus<SimEvent> events;

  /// Azar con semilla para los comportamientos que lo necesiten (Fase 3).
  /// Con la misma semilla y los mismos comandos, la partida se repite igual.
  final SeededRandom random;

  final LevelDef _level;
  final Map<String, PestDef> _pestDefs;
  final Map<String, PathTrack> _tracks;
  final WaveSpawner _spawner;
  final List<Pest> _pests = [];
  final List<PlayerCommand> _commands = [];

  /// Plagas vivas de cada oleada: una oleada se completa cuando ya
  /// aparecieron todas y este número llega a 0.
  final List<int> _aliveByWave;
  final List<bool> _completedWaves;

  int _tick = 0;
  int _corn;
  int _potatoes;
  int _nextEntityId = 1;
  BattleStatus _status = BattleStatus.playing;

  int get tick => _tick;
  int get corn => _corn;
  int get potatoes => _potatoes;
  BattleStatus get status => _status;
  List<PestView> get pests => UnmodifiableListView(_pests);
  int get totalWaves => _spawner.totalWaves;
  int get startedWaves => _spawner.startedWaves;

  /// Ticks que faltan para la siguiente oleada, o `null` si no hay ninguna
  /// en cuenta regresiva.
  int? get nextWaveCountdownTicks => _spawner.countdownTicks;

  /// Maíz que daría llamar ahora la siguiente oleada (0 si no se puede).
  int get earlyCallBonus {
    final countdown = _spawner.countdownTicks;
    if (countdown == null) return 0;
    final bonus = countdown * _level.earlyCallCornPerSecond / ticksPerSecond;
    return (bonus + 1e-9).floor();
  }

  /// Encola un comando del jugador; se aplica al inicio del siguiente tick.
  void enqueue(PlayerCommand command) => _commands.add(command);

  void step() {
    if (_status != BattleStatus.playing) return;
    _tick++;

    _applyCommands();
    _movePests();
    if (_potatoes == 0) {
      _status = BattleStatus.lost;
      events.publish(LevelLost(_tick));
      return;
    }
    _spawnPests();
    _completeWaves();
    if (_completedWaves.every((completed) => completed)) {
      _status = BattleStatus.won;
      events.publish(LevelWon(_tick, potatoesLeft: _potatoes));
    }
  }

  void _applyCommands() {
    final commands = List.of(_commands);
    _commands.clear();
    for (final command in commands) {
      switch (command) {
        case CallNextWave():
          _callNextWave(command);
      }
    }
  }

  void _callNextWave(CallNextWave command) {
    final bonus = earlyCallBonus;
    final waveNumber = _spawner.startedWaves + 1;
    if (_spawner.callNextWave() == null) {
      events.publish(
        CommandRejected(
          _tick,
          command: command,
          reason: RejectionReason.noWaveWaiting,
        ),
      );
      return;
    }
    events.publish(
      WaveStarted(_tick, waveNumber: waveNumber, calledEarly: true),
    );
    _earnCorn(bonus);
  }

  void _movePests() {
    // Compacta la lista en el mismo recorrido: las que llegan a la collca
    // se quitan sin crear una lista nueva en cada tick.
    var kept = 0;
    for (final pest in _pests) {
      pest.advance();
      if (pest.reachedCollca) {
        _reachCollca(pest);
      } else {
        _pests[kept++] = pest;
      }
    }
    _pests.length = kept;
  }

  void _reachCollca(Pest pest) {
    final lost = pest.def.potatoDamage.clamp(0, _potatoes);
    _potatoes -= lost;
    _aliveByWave[pest.wave]--;
    events.publish(
      CollcaDamaged(
        _tick,
        pestId: pest.id,
        potatoesLost: lost,
        potatoesLeft: _potatoes,
      ),
    );
  }

  void _spawnPests() {
    final update = _spawner.tick();
    if (update.startedWave case final wave?) {
      events.publish(
        WaveStarted(_tick, waveNumber: wave + 1, calledEarly: false),
      );
    }
    for (final order in update.spawns) {
      final pest = Pest(
        id: _nextEntityId++,
        def: _pestDefs[order.pestId]!,
        wave: order.wave,
        track: _tracks[order.pathId]!,
      );
      _pests.add(pest);
      _aliveByWave[order.wave]++;
      events.publish(
        PestSpawned(
          _tick,
          pestId: pest.id,
          pestType: order.pestId,
          pathId: order.pathId,
        ),
      );
    }
  }

  void _completeWaves() {
    for (var wave = 0; wave < _spawner.startedWaves; wave++) {
      if (_completedWaves[wave] ||
          !_spawner.isFullySpawned(wave) ||
          _aliveByWave[wave] > 0) {
        continue;
      }
      _completedWaves[wave] = true;
      final reward = _level.waves[wave].reward;
      events.publish(
        WaveCompleted(_tick, waveNumber: wave + 1, reward: reward),
      );
      _earnCorn(reward);
    }
  }

  void _earnCorn(int amount) {
    if (amount == 0) return;
    _corn += amount;
    events.publish(CornChanged(_tick, delta: amount, total: _corn));
  }

  /// Falla al crear la partida (y no a mitad de ella) si una oleada usa una
  /// plaga o un camino que no existen. La Fase 4 valida los JSON con
  /// mensajes más detallados; esto protege al motor.
  void _validate() {
    for (final (index, wave) in _level.waves.indexed) {
      for (final group in wave.groups) {
        if (!_pestDefs.containsKey(group.pestId)) {
          throw ArgumentError(
            'La oleada ${index + 1} usa la plaga "${group.pestId}", '
            'que no existe.',
          );
        }
        if (!_tracks.containsKey(group.pathId)) {
          throw ArgumentError(
            'La oleada ${index + 1} usa el camino "${group.pathId}", '
            'que no existe.',
          );
        }
      }
    }
  }
}
