import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/core/math/vec2.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/commands.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/simulation.dart';
import 'package:guardianes_chacra/features/battle/domain/events/sim_events.dart';
import 'package:guardianes_chacra/features/battle/domain/registry/behavior_registry.dart';
import 'package:guardianes_chacra/features/content/domain/behavior_spec.dart';
import 'package:guardianes_chacra/features/content/domain/guardian_def.dart';
import 'package:guardianes_chacra/features/content/domain/pest_def.dart';

import '../../../../helpers/battle_fixtures.dart';

/// Una partida sin plagas a la vista (la primera oleada tarda 100 s) para
/// probar los comandos con calma.
Simulation _simulation({int corn = 500}) => Simulation(
  level: testLevel(corn: corn, waves: [testWave('gorgojo', prepTime: 100)]),
  pests: pestCatalog,
  guardians: guardianCatalog,
  rules: testRules,
  seed: 1,
);

/// Aplica [commands] en un solo tick y devuelve los eventos de ese tick.
List<SimEvent> _apply(Simulation simulation, List<PlayerCommand> commands) {
  final events = <SimEvent>[];
  final subscription = simulation.events.on<SimEvent>(events.add);
  commands.forEach(simulation.enqueue);
  simulation.step();
  subscription.cancel();
  return events;
}

const _buildA = BuildGuardian(slotId: 'a', guardianType: 'hondero');

void main() {
  test('construir en un espacio libre cobra su costo', () {
    final simulation = _simulation();

    final events = _apply(simulation, [_buildA]);

    expect(events, [
      const GuardianBuilt(
        1,
        guardianId: 1,
        guardianType: 'hondero',
        slotId: 'a',
      ),
      const CornChanged(1, delta: -50, total: 450),
    ]);
    final guardian = simulation.guardians.single;
    expect(guardian.slotId, 'a');
    expect(guardian.position, const Vec2(5, 1));
    expect(guardian.level, 1);
    expect(guardian.range, 3);
    expect(guardian.targetingId, 'first');
    expect(guardian.totalSpent, 50);
  });

  group('construir se rechaza', () {
    test('si no alcanza el maíz', () {
      final simulation = _simulation(corn: 40);

      final events = _apply(simulation, [_buildA]);

      expect(events, [
        const CommandRejected(
          1,
          command: _buildA,
          reason: RejectionReason.notEnoughCorn,
        ),
      ]);
      expect(simulation.guardians, isEmpty);
      expect(simulation.corn, 40);
    });

    test('si el espacio está ocupado o no existe, o el tipo no existe', () {
      final simulation = _simulation();
      _apply(simulation, [_buildA]);

      const unknownSlot = BuildGuardian(slotId: 'z', guardianType: 'hondero');
      const unknownType = BuildGuardian(slotId: 'b', guardianType: 'condor');
      final events = _apply(simulation, [_buildA, unknownSlot, unknownType]);

      expect(events.map((event) => (event as CommandRejected).reason), [
        RejectionReason.slotOccupied,
        RejectionReason.unknownSlot,
        RejectionReason.unknownGuardianType,
      ]);
      expect(simulation.guardians, hasLength(1));
      expect(simulation.corn, 450);
    });
  });

  test('mejorar aplica el nivel siguiente y cobra su costo', () {
    final simulation = _simulation();
    _apply(simulation, [_buildA]);

    final events = _apply(simulation, [const UpgradeGuardian(1)]);

    expect(events, [
      const GuardianUpgraded(2, guardianId: 1, level: 2),
      const CornChanged(2, delta: -40, total: 410),
    ]);
    final guardian = simulation.guardians.single;
    expect(guardian.level, 2);
    expect(guardian.range, 3.5);
    expect(guardian.totalSpent, 90);

    _apply(simulation, [const UpgradeGuardian(1)]);
    expect(guardian.level, 3);
    expect(guardian.range, 4);
    expect(simulation.corn, 350);
  });

  test('después de la última mejora hay que elegir una rama', () {
    final simulation = _simulation();
    _apply(simulation, [
      _buildA,
      const UpgradeGuardian(1),
      const UpgradeGuardian(1),
    ]);
    expect(simulation.corn, 350);

    final atLastLevel = _apply(simulation, [const UpgradeGuardian(1)]);
    expect(
      (atLastLevel.single as CommandRejected).reason,
      RejectionReason.chooseBranch,
    );

    const specialize = SpecializeGuardian(1, branchId: 'piedra_pesada');
    final specialized = _apply(simulation, [specialize]);
    expect(specialized, [
      const GuardianSpecialized(3, guardianId: 1, branchId: 'piedra_pesada'),
      const CornChanged(3, delta: -100, total: 250),
    ]);
    final guardian = simulation.guardians.single;
    expect(guardian.level, 4);
    expect(guardian.branchId, 'piedra_pesada');
    expect(guardian.range, 4.5);

    final afterBranch = _apply(simulation, [
      const UpgradeGuardian(1),
      const SpecializeGuardian(1, branchId: 'honda_rapida'),
    ]);
    expect(afterBranch.map((event) => (event as CommandRejected).reason), [
      RejectionReason.maxLevel,
      RejectionReason.cannotSpecialize,
    ]);
    expect(simulation.corn, 250);
  });

  test('no se puede especializar antes de tiempo ni con una rama que no '
      'existe', () {
    final simulation = _simulation();
    _apply(simulation, [_buildA]);

    final tooEarly = _apply(simulation, [
      const SpecializeGuardian(1, branchId: 'piedra_pesada'),
    ]);
    expect(
      (tooEarly.single as CommandRejected).reason,
      RejectionReason.cannotSpecialize,
    );

    _apply(simulation, [const UpgradeGuardian(1), const UpgradeGuardian(1)]);
    final unknown = _apply(simulation, [
      const SpecializeGuardian(1, branchId: 'laser'),
    ]);
    expect(
      (unknown.single as CommandRejected).reason,
      RejectionReason.unknownBranch,
    );
  });

  test('un guardián de un solo nivel no se puede mejorar', () {
    final simulation = _simulation();
    _apply(simulation, [
      const BuildGuardian(slotId: 'a', guardianType: 'espantapajaros'),
    ]);

    final events = _apply(simulation, [const UpgradeGuardian(1)]);

    expect((events.single as CommandRejected).reason, RejectionReason.maxLevel);
  });

  group('vender', () {
    test('devuelve el 70 % de todo lo gastado y libera el espacio', () {
      final simulation = _simulation();
      _apply(simulation, [_buildA, const UpgradeGuardian(1)]);
      expect(simulation.corn, 410);
      // 50 + 40 = 90 gastado; el 70 % es 63.
      expect(simulation.sellValueOf(simulation.guardians.single), 63);

      final events = _apply(simulation, [const SellGuardian(1)]);

      expect(events, [
        const GuardianSold(2, guardianId: 1, refund: 63),
        const CornChanged(2, delta: 63, total: 473),
      ]);
      expect(simulation.guardians, isEmpty);

      _apply(simulation, [_buildA]);
      expect(simulation.guardians.single.slotId, 'a');
    });

    test('el reembolso se redondea hacia abajo', () {
      final simulation = _simulation();
      _apply(simulation, [
        const BuildGuardian(slotId: 'a', guardianType: 'espantapajaros'),
      ]);

      final events = _apply(simulation, [const SellGuardian(1)]);

      // 75 × 0,7 = 52,5.
      expect((events.first as GuardianSold).refund, 52);
    });
  });

  test('cambiar la estrategia de apuntado', () {
    final simulation = _simulation();
    _apply(simulation, [_buildA]);

    final changed = _apply(simulation, [
      const SetTargeting(1, strategy: 'strongest'),
    ]);
    expect(changed, [
      const TargetingChanged(2, guardianId: 1, strategy: 'strongest'),
    ]);
    expect(simulation.guardians.single.targetingId, 'strongest');

    final unknown = _apply(simulation, [
      const SetTargeting(1, strategy: 'random'),
    ]);
    expect(
      (unknown.single as CommandRejected).reason,
      RejectionReason.unknownTargeting,
    );
    expect(simulation.guardians.single.targetingId, 'strongest');
  });

  test('un guardián que no existe se rechaza', () {
    final simulation = _simulation();

    final events = _apply(simulation, [
      const UpgradeGuardian(99),
      const SellGuardian(99),
      const SetTargeting(99, strategy: 'last'),
    ]);

    expect(
      events.map((event) => (event as CommandRejected).reason),
      List.filled(3, RejectionReason.guardianNotFound),
    );
  });

  test('un guardián con un comportamiento desconocido falla al crear la '
      'partida', () {
    const laser = GuardianDef(
      id: 'laser',
      levels: [
        GuardianLevelDef(
          cost: 10,
          range: 3,
          targets: {PestTag.ground},
          behaviors: [BehaviorSpec('laser')],
        ),
      ],
    );

    expect(
      () => Simulation(
        level: testLevel(waves: [testWave('gorgojo')]),
        pests: pestCatalog,
        guardians: {'laser': laser},
        rules: testRules,
        seed: 1,
      ),
      throwsA(
        isA<BehaviorDataError>().having(
          (error) => error.message,
          'message',
          contains('"laser"'),
        ),
      ),
    );
  });
}
