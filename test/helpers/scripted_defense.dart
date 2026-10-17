import 'package:guardianes_chacra/features/battle/domain/engine/commands.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/simulation.dart';
import 'package:guardianes_chacra/features/battle/domain/world/guardian.dart';
import 'package:guardianes_chacra/features/content/domain/game_content.dart';
import 'package:guardianes_chacra/features/content/domain/level_def.dart';

/// Una acción del plan de un jugador "de prueba".
sealed class PlannedAction {
  const new(this.slotId);

  final String slotId;
}

final class Build extends PlannedAction {
  const new(super.slotId, this.guardianType);

  final String guardianType;
}

final class Upgrade extends PlannedAction {
  const new(super.slotId);
}

final class Specialize extends PlannedAction {
  const new(super.slotId, this.branchId);

  final String branchId;
}

/// Juega [level] sin gráficos siguiendo [plan] en orden: espera a tener el
/// maíz de la siguiente acción, la hace y sigue. Las oleadas empiezan solas.
///
/// Es una versión mínima del simulador de balance de la Fase 9: sirve para
/// comprobar que un nivel se puede ganar con una defensa razonable.
Simulation playScripted(
  GameContent content,
  LevelDef level,
  List<PlannedAction> plan, {
  int maxTicks = 30 * 60 * 20,
  void Function(Simulation simulation)? observe,
}) {
  final simulation = Simulation(
    level: level,
    pests: content.pests,
    guardians: content.guardians,
    rules: content.rules,
    seed: 1,
  );
  observe?.call(simulation);
  final pending = List.of(plan);

  GuardianView? at(String slotId) => simulation.guardians
      .where((guardian) => guardian.slotId == slotId)
      .firstOrNull;

  int costOf(PlannedAction action) => switch (action) {
    Build(:final guardianType) =>
      content.guardians[guardianType]!.levels.first.cost,
    Upgrade(:final slotId) => at(slotId)!.def.levels[at(slotId)!.level].cost,
    Specialize(:final slotId, :final branchId) => at(
      slotId,
    )!.def.branches.firstWhere((branch) => branch.id == branchId).level.cost,
  };

  PlayerCommand commandFor(PlannedAction action) => switch (action) {
    Build(:final slotId, :final guardianType) => BuildGuardian(
      slotId: slotId,
      guardianType: guardianType,
    ),
    Upgrade(:final slotId) => UpgradeGuardian(at(slotId)!.id),
    Specialize(:final slotId, :final branchId) => SpecializeGuardian(
      at(slotId)!.id,
      branchId: branchId,
    ),
  };

  for (
    var tick = 0;
    tick < maxTicks && simulation.status == BattleStatus.playing;
    tick++
  ) {
    if (pending.isNotEmpty && simulation.corn >= costOf(pending.first)) {
      simulation.enqueue(commandFor(pending.removeAt(0)));
    }
    simulation.step();
  }
  return simulation;
}
