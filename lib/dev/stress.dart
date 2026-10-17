import 'package:guardianes_chacra/core/math/vec2.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/commands.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/sim_time.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/simulation.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/simulation_cheats.dart';
import 'package:guardianes_chacra/features/battle/domain/world/path_track.dart';
import 'package:guardianes_chacra/features/content/domain/game_content.dart';
import 'package:guardianes_chacra/features/content/domain/level_def.dart';

/// Cuánto tardó la simulación en la prueba de estrés.
typedef StressReport = ({
  String level,
  int guardians,

  /// El máximo de plagas vivas a la vez.
  int peakPests,

  /// Los ticks medidos (sin el primer segundo, de calentamiento).
  int ticks,
  double averageMs,
  double p95Ms,
  double maxMs,
});

/// Mide cuánto tarda un tick de la simulación con muchas plagas, sin
/// gráficos:
///
/// 1. toma el nivel con más espacios y, si no alcanzan para [guardians],
///    agrega espacios junto al primer camino;
/// 2. construye [guardians] guardianes de todos los tipos, mejorados y
///    especializados (así hay ralentizar, quemar y aturdir a la vez);
/// 3. lanza [pests] plagas como el botón de estrés del panel de desarrollo
///    y corre [seconds] segundos de juego, con maíz infinito y la collca
///    invencible para que la partida no termine.
StressReport runStress(
  GameContent content, {
  int pests = 150,
  int guardians = 15,
  int seconds = 30,
}) {
  final base = content.levels.reduce(
    (a, b) => b.map.buildSlots.length > a.map.buildSlots.length ? b : a,
  );
  final level = _withSlots(base, guardians);
  final cheats = SimulationCheats()
    ..infiniteCorn = true
    ..invincible = true;
  final simulation = Simulation(
    level: level,
    pests: content.pests,
    guardians: content.guardians,
    rules: content.rules,
    seed: 1,
    cheats: cheats,
  );

  // Construir, mejorar y especializar: un paso cada uno, porque los
  // comandos se aplican en el tick siguiente.
  final types = content.guardians.keys.toList();
  for (final (index, slot) in level.map.buildSlots.take(guardians).indexed) {
    simulation.enqueue(
      BuildGuardian(slotId: slot.id, guardianType: types[index % types.length]),
    );
  }
  simulation.step();
  for (final guardian in simulation.guardians) {
    for (var level = 1; level < guardian.def.levels.length; level++) {
      simulation.enqueue(UpgradeGuardian(guardian.id));
    }
  }
  simulation.step();
  for (final guardian in simulation.guardians) {
    if (guardian.def.branches.isNotEmpty) {
      simulation.enqueue(
        SpecializeGuardian(
          guardian.id,
          branchId: guardian.def.branches.first.id,
        ),
      );
    }
  }
  simulation
    ..enqueue(StressTest(count: pests))
    ..enqueue(const CallNextWave());

  final watch = Stopwatch();
  final samples = <int>[];
  var peak = 0;
  final total = seconds * ticksPerSecond;
  for (var tick = 0; tick < total; tick++) {
    watch
      ..reset()
      ..start();
    simulation.step();
    watch.stop();
    // El primer segundo calienta la máquina virtual de Dart: no cuenta.
    if (tick >= ticksPerSecond) samples.add(watch.elapsedMicroseconds);
    if (simulation.pests.length > peak) peak = simulation.pests.length;
  }

  samples.sort();
  final sum = samples.fold(0, (sum, sample) => sum + sample);
  return (
    level: base.id,
    guardians: simulation.guardians.length,
    peakPests: peak,
    ticks: samples.length,
    averageMs: sum / samples.length / 1000,
    p95Ms: samples[(samples.length * 0.95).floor()] / 1000,
    maxMs: samples.last / 1000,
  );
}

/// [level] con al menos [count] espacios: los que faltan se agregan a una
/// casilla del primer camino, repartidos a lo largo de él.
LevelDef _withSlots(LevelDef level, int count) {
  final missing = count - level.map.buildSlots.length;
  if (missing <= 0) return level;
  final track = PathTrack(level.map.paths.first.points);
  final map = level.map;
  return LevelDef(
    id: level.id,
    mapFile: level.mapFile,
    map: MapDef(
      width: map.width,
      height: map.height,
      collca: map.collca,
      paths: map.paths,
      buildSlots: [
        ...map.buildSlots,
        for (var i = 1; i <= missing; i++)
          if (track.positionAt(track.length * i / (missing + 1))
              case final point)
            BuildSlotDef(id: 'estres_$i', position: Vec2(point.x, point.y + 1)),
      ],
    ),
    startingCorn: level.startingCorn,
    startingPotatoes: level.startingPotatoes,
    earlyCallCornPerSecond: level.earlyCallCornPerSecond,
    waves: level.waves,
  );
}
