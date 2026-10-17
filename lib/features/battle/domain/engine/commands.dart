import 'package:meta/meta.dart';

/// Una acción del jugador. La capa visual no modifica el estado: envía
/// comandos con `Simulation.enqueue` y la simulación los aplica al inicio
/// del tick siguiente. Con la semilla y la lista de comandos (con su tick)
/// se puede reproducir una partida completa.
///
/// Es `sealed`: en la Fase 3 llegan construir, mejorar, vender y cambiar la
/// estrategia de apuntado, y el compilador avisará dónde falta manejarlos.
@immutable
sealed class PlayerCommand {
  const new();
}

/// Empieza ya la oleada que está en cuenta regresiva, a cambio de maíz
/// extra por el tiempo que se salta.
final class CallNextWave extends PlayerCommand {
  const new();

  @override
  bool operator ==(Object other) => other is CallNextWave;

  @override
  int get hashCode => (CallNextWave).hashCode;

  @override
  String toString() => 'CallNextWave';
}
