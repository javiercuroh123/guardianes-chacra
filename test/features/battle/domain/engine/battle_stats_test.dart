import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/core/events/event_bus.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/battle_stats.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/sim_time.dart';
import 'package:guardianes_chacra/features/battle/domain/events/sim_events.dart';

void main() {
  test('cuenta el maíz ganado, no el gastado ni lo que devuelve vender', () {
    final events = EventBus<SimEvent>();
    final stats = BattleStats(events);

    events
      // Recompensa de una plaga.
      ..publish(const CornChanged(10, delta: 4, total: 224))
      // Construir.
      ..publish(const CornChanged(20, delta: -60, total: 164))
      // Vender: entra maíz, pero no es cosecha.
      ..publish(const GuardianSold(30, guardianId: 1, refund: 42))
      ..publish(const CornChanged(30, delta: 42, total: 206))
      // Recompensa de la oleada.
      ..publish(const CornChanged(40, delta: 20, total: 226));

    expect(stats.cornHarvested, 24);
  });

  test('los segundos que faltan se redondean hacia arriba', () {
    expect(ticksToWholeSeconds(ticksPerSecond * 15), 15);
    expect(ticksToWholeSeconds(ticksPerSecond * 14 + 1), 15);
    expect(ticksToWholeSeconds(1), 1);
    expect(ticksToWholeSeconds(0), 0);
  });
}
