import 'package:guardianes_chacra/core/events/event_bus.dart';
import 'package:guardianes_chacra/features/battle/domain/events/sim_events.dart';

/// Lo que el resumen de la victoria muestra y la simulación no guarda. Se
/// cuenta escuchando los eventos, sin tocar el motor.
class BattleStats {
  new(EventBus<SimEvent> events) {
    events
      ..on<CornChanged>((event) {
        if (event.delta > 0) _cornHarvested += event.delta;
      })
      // Lo que devuelve vender no se cosechó: se recuperó.
      ..on<GuardianSold>((event) => _cornHarvested -= event.refund);
  }

  int _cornHarvested = 0;

  /// Maíz ganado en el nivel: recompensas de plagas y oleadas y bonos por
  /// llamar oleadas antes de tiempo.
  int get cornHarvested => _cornHarvested;
}
