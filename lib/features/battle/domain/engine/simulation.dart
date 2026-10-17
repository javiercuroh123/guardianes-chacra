import 'dart:collection';
import 'dart:math' as math;

import 'package:guardianes_chacra/core/events/event_bus.dart';
import 'package:guardianes_chacra/core/math/seeded_random.dart';
import 'package:guardianes_chacra/core/math/vec2.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/attacks/guardian_behavior.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/damage.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/effects/status_effect.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/battle_context.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/commands.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/sim_time.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/simulation_cheats.dart';
import 'package:guardianes_chacra/features/battle/domain/events/sim_events.dart';
import 'package:guardianes_chacra/features/battle/domain/registry/behavior_registry.dart';
import 'package:guardianes_chacra/features/battle/domain/waves/wave_spawner.dart';
import 'package:guardianes_chacra/features/battle/domain/world/guardian.dart';
import 'package:guardianes_chacra/features/battle/domain/world/path_track.dart';
import 'package:guardianes_chacra/features/battle/domain/world/pest.dart';
import 'package:guardianes_chacra/features/battle/domain/world/projectile.dart';
import 'package:guardianes_chacra/features/content/domain/battle_rules.dart';
import 'package:guardianes_chacra/features/content/domain/guardian_def.dart';
import 'package:guardianes_chacra/features/content/domain/level_def.dart';
import 'package:guardianes_chacra/features/content/domain/pest_def.dart';

part 'simulation_commands.dart';

enum BattleStatus { playing, won, lost }

/// La partida en Dart puro. No conoce Flame, ni el reloj real, ni la
/// pantalla: avanza exactamente un tick con cada [step] y publica en
/// [events] lo que ocurre.
///
/// Orden dentro de un tick:
/// 1. Comandos del jugador.
/// 2. Efectos de estado (la quemadura hace su daño).
/// 3. Habilidades de las plagas (invocar).
/// 4. Movimiento, llegadas a la collca y fin de los efectos que vencen.
/// 5. Derrota.
/// 6. Proyectiles en vuelo (impactos).
/// 7. Auras y ataques de los guardianes, en el orden en que se construyeron.
/// 8. Plagas derrotadas (maíz y habilidades al morir, como dividirse).
/// 9. Plagas nuevas: las creadas en este tick y las de la oleada.
/// 10. Oleadas completadas y victoria.
///
/// Toda plaga o proyectil nuevo empieza a moverse en el tick siguiente.
class Simulation {
  new({
    required LevelDef level,
    required Map<String, PestDef> pests,
    required this._rules,
    required int seed,
    Map<String, GuardianDef> guardians = const {},
    BehaviorRegistry? registry,
    EventBus<SimEvent>? events,
    SimulationCheats? cheats,
    int extraCorn = 0,
  }) : assert(extraCorn >= 0, 'extraCorn no puede ser negativo'),
       events = events ?? EventBus<SimEvent>(),
       cheats = cheats ?? SimulationCheats(),
       random = SeededRandom(seed),
       _level = level,
       _registry = registry ?? BehaviorRegistry.withDefaults(),
       _pestDefs = Map.unmodifiable(pests),
       _guardianDefs = Map.unmodifiable(guardians),
       _slots = {for (final slot in level.map.buildSlots) slot.id: slot},
       _tracks = {
         for (final path in level.map.paths) path.id: PathTrack(path.points),
       },
       _spawner = WaveSpawner(level.waves),
       _corn = level.startingCorn + extraCorn,
       _potatoes = level.startingPotatoes,
       _aliveByWave = List.filled(level.waves.length, 0),
       _completedWaves = List.filled(level.waves.length, false) {
    _validate();
  }

  final EventBus<SimEvent> events;

  /// Trucos de desarrollo (apagados salvo con las herramientas de desarrollo).
  final SimulationCheats cheats;

  /// Azar con semilla para los comportamientos que lo necesiten. Con la
  /// misma semilla y los mismos comandos, la partida se repite igual.
  final SeededRandom random;

  final LevelDef _level;
  final BattleRules _rules;
  final BehaviorRegistry _registry;
  final Map<String, PestDef> _pestDefs;
  final Map<String, GuardianDef> _guardianDefs;
  final Map<String, BuildSlotDef> _slots;
  final Map<String, PathTrack> _tracks;
  final WaveSpawner _spawner;
  final List<Pest> _pests = [];
  final List<Guardian> _guardians = [];
  final List<Projectile> _projectiles = [];
  final List<PlayerCommand> _commands = [];

  /// Plagas creadas durante el tick (divididas o invocadas). Entran al
  /// juego en el paso de plagas nuevas.
  final List<Pest> _newborn = [];

  /// Plagas vivas de cada oleada: una oleada se completa cuando ya
  /// aparecieron todas y este número llega a 0.
  final List<int> _aliveByWave;
  final List<bool> _completedWaves;

  /// La única puerta de los comportamientos hacia la simulación.
  late final BattleContext _context = _SimulationContext(this);

  int _tick = 0;
  int _corn;
  int _potatoes;
  int _nextPestId = 1;
  int _nextGuardianId = 1;
  int _nextProjectileId = 1;
  BattleStatus _status = BattleStatus.playing;
  bool _revived = false;

  /// Plagas que faltan por aparecer de la prueba de estrés (ver
  /// [StressTest]).
  int _stressRemaining = 0;

  int get tick => _tick;
  int get corn => _corn;
  int get potatoes => _potatoes;
  BattleStatus get status => _status;

  /// Si ya se usó [revive] en esta partida.
  bool get revived => _revived;

  /// Si se puede seguir jugando después de perder: una vez por partida.
  bool get canRevive => _status == BattleStatus.lost && !_revived;
  List<PestView> get pests => UnmodifiableListView(_pests);

  /// Guardianes construidos, en el orden en que se construyeron (también
  /// es el orden en que atacan).
  List<GuardianView> get guardians => UnmodifiableListView(_guardians);

  List<ProjectileView> get projectiles => UnmodifiableListView(_projectiles);

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

  /// Si alcanza el maíz para pagar [cost] (siempre, con maíz infinito).
  bool canAfford(int cost) => cheats.infiniteCorn || _corn >= cost;

  /// Maíz que devolvería vender [guardian] ahora (redondeado hacia abajo).
  int sellValueOf(GuardianView guardian) =>
      (guardian.totalSpent * _rules.sellRefundRate + 1e-9).floor();

  /// Encola un comando del jugador; se aplica al inicio del siguiente tick.
  void enqueue(PlayerCommand command) => _commands.add(command);

  /// Sigue la partida después de perder, con [potatoes] papas en la collca
  /// (la recompensa de un anuncio). Solo una vez por partida: devuelve
  /// `false` si no se puede (ver [canRevive]).
  ///
  /// Las plagas en pantalla se van sin dar maíz: las que hicieron perder
  /// siguen en la puerta de la collca y, si se quedaran, se comerían las
  /// papas nuevas al instante. Las oleadas siguen como iban.
  ///
  /// No es un comando porque los comandos se aplican dentro de un tick, y
  /// con la partida perdida ya no corren ticks.
  bool revive(int potatoes) {
    if (!canRevive || potatoes <= 0) return false;
    _revived = true;
    _clearPests();
    _potatoes = potatoes;
    _status = BattleStatus.playing;
    events.publish(LevelRevived(_tick, potatoes: potatoes));
    return true;
  }

  void step() {
    if (_status != BattleStatus.playing) return;
    _tick++;

    // `this.` hace falta: los comandos viven en una extensión (en
    // simulation_commands.dart) y Dart no busca extensiones sin él.
    // ignore: unnecessary_this
    this._applyCommands();
    _tickEffects();
    _tickAbilities();
    _movePests();
    if (_potatoes == 0) {
      _status = BattleStatus.lost;
      events.publish(LevelLost(_tick));
      return;
    }
    _moveProjectiles();
    _applyAuras();
    _guardiansAct();
    _resolveDeaths();
    _spawnPests();
    _completeWaves();
    if (_completedWaves.every((completed) => completed)) {
      _status = BattleStatus.won;
      events.publish(LevelWon(_tick, potatoesLeft: _potatoes));
    }
  }

  /// Quita las plagas en pantalla sin dar maíz (saltar oleada y revivir).
  /// Cuentan como fuera de su oleada, así que la oleada puede completarse.
  void _clearPests() {
    for (final pest in _pests) {
      if (!pest.isAlive) continue;
      pest.removed = true;
      _aliveByWave[pest.wave]--;
      events.publish(
        PestDefeated(_tick, pestId: pest.id, pestType: pest.def.id, reward: 0),
      );
    }
    _pests.removeWhere((pest) => pest.removed);
  }

  void _tickEffects() {
    for (final pest in _pests) {
      if (pest.isAlive) pest.tickEffects(_context);
    }
  }

  void _tickAbilities() {
    for (final pest in _pests) {
      if (!pest.isAlive) continue;
      for (final ability in pest.abilities) {
        ability.onTick(pest, _context);
      }
    }
  }

  void _movePests() {
    // Compacta la lista en el mismo recorrido: las que llegan a la collca
    // se quitan sin crear una lista nueva en cada tick. Las derrotadas en
    // este tick (por ejemplo, por la quemadura) no se mueven; se retiran
    // en `_resolveDeaths`.
    var kept = 0;
    for (final pest in _pests) {
      if (pest.isAlive) {
        pest
          ..advance()
          ..expireEffects();
        if (pest.reachedCollca) {
          _reachCollca(pest);
          continue;
        }
      }
      _pests[kept++] = pest;
    }
    _pests.length = kept;
  }

  void _reachCollca(Pest pest) {
    pest.removed = true;
    final lost = cheats.invincible
        ? 0
        : pest.def.potatoDamage.clamp(0, _potatoes);
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

  void _moveProjectiles() {
    var kept = 0;
    for (final projectile in _projectiles) {
      if (projectile.advance()) {
        _impact(projectile);
      } else {
        _projectiles[kept++] = projectile;
      }
    }
    _projectiles.length = kept;
  }

  /// Un proyectil sin área golpea solo a su objetivo (si sigue vivo); uno
  /// con área golpea a todas las plagas atacables cerca del impacto.
  void _impact(Projectile projectile) {
    events.publish(
      ProjectileImpacted(
        _tick,
        projectileId: projectile.id,
        position: projectile.position,
      ),
    );
    final shot = projectile.shot;
    final victims = shot.splashRadius > 0
        ? _attackable(
            projectile.targets,
            center: projectile.position,
            radius: shot.splashRadius,
          )
        : [if (projectile.target.isAlive) projectile.target];
    for (final pest in victims) {
      _hit(pest, shot.hit);
      for (final effect in shot.onHit) {
        _applyEffect(pest, effect);
      }
    }
  }

  /// Cada guardián recibe la mayor bonificación de las auras que lo
  /// alcanzan: no se suman.
  void _applyAuras() {
    for (final guardian in _guardians) {
      var bonus = 0.0;
      for (final source in _guardians) {
        for (final behavior in source.behaviors) {
          bonus = math.max(
            bonus,
            behavior.attackSpeedBonusFor(source, guardian),
          );
        }
      }
      guardian.attackSpeedMultiplier = 1 + bonus;
    }
  }

  void _guardiansAct() {
    for (final guardian in _guardians) {
      for (final behavior in guardian.behaviors) {
        behavior.act(guardian, _context);
      }
    }
  }

  void _resolveDeaths() {
    final defeated = <Pest>[];
    var kept = 0;
    for (final pest in _pests) {
      if (pest.health <= 0) {
        defeated.add(pest);
      } else {
        _pests[kept++] = pest;
      }
    }
    _pests.length = kept;

    for (final pest in defeated) {
      pest.removed = true;
      _aliveByWave[pest.wave]--;
      events.publish(
        PestDefeated(
          _tick,
          pestId: pest.id,
          pestType: pest.def.id,
          reward: pest.def.cornReward,
        ),
      );
      _earnCorn(pest.def.cornReward);
      for (final ability in pest.abilities) {
        ability.onDeath(pest, _context);
      }
    }
  }

  void _spawnPests() {
    _newborn
      ..forEach(_addPest)
      ..clear();

    final update = _spawner.tick();
    if (update.startedWave case final wave?) {
      events.publish(
        WaveStarted(_tick, waveNumber: wave + 1, calledEarly: false),
      );
    }
    if (_stressRemaining > 0 && _tick.isEven) _spawnStressPest();
    for (final order in update.spawns) {
      _aliveByWave[order.wave]++;
      _addPest(
        _createPest(
          _pestDefs[order.pestId]!,
          wave: order.wave,
          pathId: order.pathId,
          track: _tracks[order.pathId]!,
        ),
      );
    }
  }

  /// Una plaga de la prueba de estrés: del primer tipo del nivel, por el
  /// camino que toque. Cuenta como de la última oleada empezada.
  void _spawnStressPest() {
    _stressRemaining--;
    final paths = _level.map.paths;
    final path = paths[_stressRemaining % paths.length];
    final wave = math.max(0, _spawner.startedWaves - 1);
    _aliveByWave[wave]++;
    _addPest(
      _createPest(
        _pestDefs[_level.waves.first.groups.first.pestId]!,
        wave: wave,
        pathId: path.id,
        track: _tracks[path.id]!,
      ),
    );
  }

  Pest _createPest(
    PestDef def, {
    required int wave,
    required String pathId,
    required PathTrack track,
    double distance = 0,
  }) => Pest(
    id: _nextPestId++,
    def: def,
    wave: wave,
    pathId: pathId,
    track: track,
    distance: distance,
    abilities: [
      for (final spec in def.abilities) _registry.createAbility(spec),
    ],
  );

  void _addPest(Pest pest) {
    _pests.add(pest);
    events.publish(
      PestSpawned(
        _tick,
        pestId: pest.id,
        pestType: pest.def.id,
        pathId: pest.pathId,
      ),
    );
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

  // --- Mecánicas que usan los comportamientos (vía `_SimulationContext`).

  /// Plagas vivas con alguna etiqueta de [tags] a [radius] o menos de
  /// [center].
  List<Pest> _attackable(
    Set<PestTag> tags, {
    required Vec2 center,
    required double radius,
  }) {
    final maxDistanceSquared = radius * radius + 1e-9;
    return [
      for (final pest in _pests)
        if (pest.isAlive &&
            pest.def.tags.any(tags.contains) &&
            center.distanceSquaredTo(pest.position) <= maxDistanceSquared)
          pest,
    ];
  }

  void _hit(Pest pest, Hit hit) {
    if (!pest.isAlive) return;
    final amount = damageDealt(hit, pest.def, _rules);
    pest.health -= amount;
    events.publish(
      PestDamaged(_tick, pestId: pest.id, amount: amount, damageType: hit.type),
    );
  }

  void _applyEffect(Pest pest, StatusEffect effect) {
    if (pest.isAlive) pest.applyEffect(effect);
  }

  void _launchProjectile(Guardian from, Pest target, ProjectileShot shot) {
    final projectile = Projectile(
      id: _nextProjectileId++,
      guardianId: from.id,
      position: from.position,
      target: target,
      shot: shot,
      targets: from.targets,
    );
    _projectiles.add(projectile);
    events.publish(
      GuardianFired(
        _tick,
        guardianId: from.id,
        pestId: target.id,
        projectileId: projectile.id,
      ),
    );
  }

  void _spawnFrom(Pest parent, String pestId, double distance) {
    _aliveByWave[parent.wave]++;
    _newborn.add(
      _createPest(
        _pestDefs[pestId]!,
        wave: parent.wave,
        pathId: parent.pathId,
        track: parent.track,
        distance: distance,
      ),
    );
  }

  void _earnCorn(int amount) {
    if (amount == 0) return;
    _corn += amount;
    events.publish(CornChanged(_tick, delta: amount, total: _corn));
  }

  void _spendCorn(int amount) {
    if (amount == 0 || cheats.infiniteCorn) return;
    _corn -= amount;
    events.publish(CornChanged(_tick, delta: -amount, total: _corn));
  }

  // --- Validación de los datos al crear la partida.

  /// Falla al crear la partida (y no a mitad de ella) si los datos hacen
  /// referencia a algo que no existe o a un comportamiento mal definido.
  /// La Fase 4 valida los JSON con mensajes por archivo; esto protege al
  /// motor.
  void _validate() {
    if (_slots.length != _level.map.buildSlots.length) {
      throw ArgumentError('Hay espacios de construcción con el mismo id.');
    }
    for (final def in _guardianDefs.values) {
      if (def.levels.isEmpty) {
        throw ArgumentError('El guardián "${def.id}" no tiene niveles.');
      }
      _withContext('El guardián "${def.id}"', () {
        _registry.targeting(def.defaultTargeting);
        [
          ...def.levels,
          for (final branch in def.branches) branch.level,
        ].forEach(_createBehaviors);
      });
    }
    for (final def in _pestDefs.values) {
      for (final spec in def.abilities) {
        final ability = _withContext(
          'La plaga "${def.id}"',
          () => _registry.createAbility(spec),
        );
        for (final pestId in ability.spawnsPests) {
          if (!_pestDefs.containsKey(pestId)) {
            throw ArgumentError(
              'La plaga "${def.id}" crea la plaga "$pestId", que no existe.',
            );
          }
        }
      }
    }
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

  List<GuardianBehavior> _createBehaviors(GuardianLevelDef level) => [
    for (final spec in level.behaviors) _registry.createGuardianBehavior(spec),
  ];

  /// Antepone [context] al mensaje de un error de datos de comportamiento.
  static T _withContext<T>(String context, T Function() action) {
    try {
      return action();
    } on BehaviorDataError catch (error) {
      throw BehaviorDataError('$context: ${error.message}');
    }
  }
}

/// Lo que ven los comportamientos de la simulación. Es un objeto aparte
/// para que la capa visual, que solo recibe la [Simulation], no pueda
/// llamar a `hit` ni a `spawnPest`.
class _SimulationContext implements BattleContext {
  new(this._simulation);

  final Simulation _simulation;

  @override
  int get tick => _simulation._tick;

  @override
  SeededRandom get random => _simulation.random;

  @override
  List<Pest> targetsFor(Guardian guardian) => _simulation._attackable(
    guardian.targets,
    center: guardian.position,
    radius: guardian.range,
  );

  @override
  void launchProjectile({
    required Guardian from,
    required Pest target,
    required ProjectileShot shot,
  }) => _simulation._launchProjectile(from, target, shot);

  @override
  void hit(Pest pest, Hit hit) => _simulation._hit(pest, hit);

  @override
  void applyEffect(Pest pest, StatusEffect effect) =>
      _simulation._applyEffect(pest, effect);

  @override
  void spawnPest(
    String pestId, {
    required Pest from,
    required double distance,
  }) => _simulation._spawnFrom(from, pestId, distance);

  @override
  void publish(SimEvent event) => _simulation.events.publish(event);
}
