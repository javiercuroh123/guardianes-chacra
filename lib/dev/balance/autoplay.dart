import 'package:guardianes_chacra/core/math/vec2.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/commands.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/sim_time.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/simulation.dart';
import 'package:guardianes_chacra/features/battle/domain/events/sim_events.dart';
import 'package:guardianes_chacra/features/battle/domain/world/path_track.dart';
import 'package:guardianes_chacra/features/content/domain/game_content.dart';
import 'package:guardianes_chacra/features/content/domain/guardian_def.dart';
import 'package:guardianes_chacra/features/content/domain/level_def.dart';
import 'package:guardianes_chacra/features/progress/domain/progress.dart';
import 'package:guardianes_chacra/features/progress/domain/progression.dart';

/// Una forma de jugar automática y genérica: sirve en cualquier mapa porque
/// no nombra espacios, los elige por cuánto camino cubren.
///
/// Cada vez que no tiene nada pendiente decide lo siguiente:
///
/// 1. Si tiene menos de [buildFirst] guardianes, construye uno más (el
///    siguiente tipo de [types], en el mejor espacio libre).
/// 2. Si no, mejora al guardián de menor nivel (si [upgrades]).
/// 3. Con todos al máximo, elige la primera rama del que no la tenga.
/// 4. Después, construye en el siguiente espacio libre, hasta
///    [maxGuardians].
///
/// Espera a tener el maíz de lo que decidió; las oleadas empiezan solas.
class Strategy {
  const new({
    required this.name,
    required this.description,
    this.types,
    this.buildFirst = 4,
    this.upgrades = true,
    this.maxGuardians,
  });

  final String name;
  final String description;

  /// Los tipos que construye, en orden y repitiendo. `null`: todos los
  /// desbloqueados, en el orden del contenido.
  final List<String>? types;

  final int buildFirst;
  final bool upgrades;
  final int? maxGuardians;
}

/// Las cuatro estrategias del simulador de balance.
const List<Strategy> balanceStrategies = [
  Strategy(
    name: 'minima',
    description: '3 Honderos sin mejoras: debería perder',
    types: ['hondero'],
    buildFirst: 3,
    upgrades: false,
    maxGuardians: 3,
  ),
  Strategy(
    name: 'honderos',
    description: 'Solo Honderos, construyendo y mejorando',
    types: ['hondero'],
  ),
  Strategy(
    name: 'mixta',
    description: 'Todos los guardianes disponibles, por turnos',
  ),
  Strategy(
    name: 'mejoras',
    description: 'Pocos guardianes, mejorados al máximo antes de seguir',
    buildFirst: 2,
  ),
];

/// Cómo terminó una partida automática.
typedef AutoplayResult = ({
  String level,
  String strategy,
  bool won,

  /// La oleada en que se perdió (`null` si ganó).
  int? waveLost,
  int totalWaves,
  int potatoesLeft,
  int startingPotatoes,
  int cornLeft,
  int cornSpent,
  int guardiansBuilt,
  double seconds,
});

/// Juega [level] con [strategy] sin gráficos, con los guardianes que el
/// jugador tendría al llegar (los niveles anteriores ganados con 3
/// estrellas).
AutoplayResult autoplay(
  GameContent content,
  LevelDef level,
  Strategy strategy, {
  int maxSeconds = 30 * 60,
  void Function(Simulation simulation)? observe,
}) {
  final available = guardiansAvailableAt(content, level);
  final simulation = Simulation(
    level: level,
    pests: content.pests,
    guardians: available,
    rules: content.rules,
    seed: 1,
  );
  observe?.call(simulation);
  var cornSpent = 0;
  var built = 0;
  simulation.events
    ..on<CornChanged>((event) {
      if (event.delta < 0) cornSpent -= event.delta;
    })
    ..on<GuardianBuilt>((_) => built++);

  final slots = rankSlotsByCoverage(level);
  final types = [
    for (final type in strategy.types ?? available.keys)
      if (available.containsKey(type)) type,
  ];
  var nextType = 0;

  ({PlayerCommand command, int cost})? decide() {
    final guardians = simulation.guardians;
    final used = {for (final guardian in guardians) guardian.slotId};
    final free = slots.where((slot) => !used.contains(slot)).toList();
    final canBuildMore =
        free.isNotEmpty &&
        types.isNotEmpty &&
        guardians.length < (strategy.maxGuardians ?? slots.length);

    ({PlayerCommand command, int cost}) build() {
      final def = available[types[nextType % types.length]]!;
      return (
        command: BuildGuardian(slotId: free.first, guardianType: def.id),
        cost: def.levels.first.cost,
      );
    }

    if (canBuildMore && guardians.length < strategy.buildFirst) return build();
    if (strategy.upgrades) {
      final upgradable =
          guardians
              .where((g) => g.branchId == null && g.level < g.def.levels.length)
              .toList()
            ..sort((a, b) => a.level.compareTo(b.level));
      if (upgradable.isNotEmpty) {
        final guardian = upgradable.first;
        return (
          command: UpgradeGuardian(guardian.id),
          cost: guardian.def.levels[guardian.level].cost,
        );
      }
      final unspecialized = guardians.where(
        (g) => g.branchId == null && g.def.branches.isNotEmpty,
      );
      if (unspecialized.isNotEmpty) {
        final guardian = unspecialized.first;
        final branch = guardian.def.branches.first;
        return (
          command: SpecializeGuardian(guardian.id, branchId: branch.id),
          cost: branch.level.cost,
        );
      }
    }
    return canBuildMore ? build() : null;
  }

  ({PlayerCommand command, int cost})? pending;
  final maxTicks = maxSeconds * ticksPerSecond;
  while (simulation.status == BattleStatus.playing &&
      simulation.tick < maxTicks) {
    pending ??= decide();
    if (pending != null && simulation.canAfford(pending.cost)) {
      simulation.enqueue(pending.command);
      if (pending.command is BuildGuardian) nextType++;
      pending = null;
    }
    simulation.step();
  }

  final won = simulation.status == BattleStatus.won;
  return (
    level: level.id,
    strategy: strategy.name,
    won: won,
    waveLost: won ? null : simulation.startedWaves,
    totalWaves: simulation.totalWaves,
    potatoesLeft: simulation.potatoes,
    startingPotatoes: level.startingPotatoes,
    cornLeft: simulation.corn,
    cornSpent: cornSpent,
    guardiansBuilt: built,
    seconds: simulation.tick / ticksPerSecond,
  );
}

/// Los guardianes que tendría un jugador al llegar a [level] habiendo
/// ganado los niveles anteriores con 3 estrellas.
Map<String, GuardianDef> guardiansAvailableAt(
  GameContent content,
  LevelDef level,
) {
  final before = content.levels.takeWhile((other) => other.id != level.id);
  final progress = const Progress().withUnlocked(
    levels: [for (final other in before) other.id],
  );
  final played = before.fold(
    progress,
    (progress, other) => progress.withResult(other.id, stars: 3),
  );
  final progression = Progression.of(content);
  return {
    for (final MapEntry(:key, :value) in content.guardians.entries)
      if (progression.canBuild(played, key)) key: value,
  };
}

/// Los espacios de [level] en el orden en que conviene ocuparlos.
///
/// La cobertura de un espacio es cuántos puntos de camino (uno cada cuarto
/// de casilla) quedan a [radius] casillas o menos. Con varios caminos, se
/// turnan: el mejor espacio para el tramo propio de cada camino, luego el
/// del siguiente, y así; los tramos compartidos (cerca de la collca) van
/// después, porque dejan menos tiempo para atacar. Con un solo camino es
/// simplemente de mayor a menor cobertura. A igualdad, el orden del mapa.
List<String> rankSlotsByCoverage(LevelDef level, {double radius = 3}) {
  List<Vec2> samplesOf(PathDef path) {
    final track = PathTrack(path.points);
    return [
      for (var distance = 0.0; distance <= track.length; distance += 0.25)
        track.positionAt(distance),
    ];
  }

  final perPath = [for (final path in level.map.paths) samplesOf(path)];
  bool sharedWithOther(Vec2 point, int path) => [
    for (final (index, samples) in perPath.indexed)
      if (index != path) samples,
  ].any((samples) => samples.any((other) => other.distanceTo(point) < 0.3));
  final own = [
    for (final (index, samples) in perPath.indexed)
      [
        for (final point in samples)
          if (!sharedWithOther(point, index)) point,
      ],
  ];
  final all = [for (final samples in perPath) ...samples];

  int covered(BuildSlotDef slot, List<Vec2> points) =>
      points.where((point) => point.distanceTo(slot.position) <= radius).length;

  final remaining = [...level.map.buildSlots];
  final order = <String>[];
  BuildSlotDef best(int Function(BuildSlotDef slot) score) {
    var pick = remaining.first;
    for (final slot in remaining.skip(1)) {
      final (a, b) = (score(slot), score(pick));
      if (a > b || (a == b && covered(slot, all) > covered(pick, all))) {
        pick = slot;
      }
    }
    return pick;
  }

  // Turnos por los tramos propios de cada camino.
  final active = {for (var i = 0; i < perPath.length; i++) i};
  while (remaining.isNotEmpty && active.isNotEmpty) {
    for (final path in [...active]) {
      if (remaining.isEmpty) break;
      final pick = best((slot) => covered(slot, own[path]));
      if (covered(pick, own[path]) == 0) {
        active.remove(path);
        continue;
      }
      remaining.remove(pick);
      order.add(pick.id);
    }
  }
  // El resto, por cobertura total.
  while (remaining.isNotEmpty) {
    final pick = best((slot) => covered(slot, all));
    remaining.remove(pick);
    order.add(pick.id);
  }
  return order;
}

/// Cada estrategia en cada nivel.
List<AutoplayResult> runBalance(GameContent content) => [
  for (final level in content.levels)
    for (final strategy in balanceStrategies)
      autoplay(content, level, strategy),
];

const _csvHeader =
    'nivel,estrategia,resultado,oleada_perdida,oleadas,papas,papas_iniciales,'
    'maiz_sobrante,maiz_gastado,guardianes,segundos';

/// Los resultados en CSV (separado por comas, con encabezado).
String balanceCsv(List<AutoplayResult> results) {
  final rows = [
    _csvHeader,
    for (final r in results)
      [
        r.level,
        r.strategy,
        if (r.won) 'gana' else 'pierde',
        r.waveLost ?? '',
        r.totalWaves,
        r.potatoesLeft,
        r.startingPotatoes,
        r.cornLeft,
        r.cornSpent,
        r.guardiansBuilt,
        r.seconds.toStringAsFixed(1),
      ].join(','),
  ];
  return '${rows.join('\n')}\n';
}
