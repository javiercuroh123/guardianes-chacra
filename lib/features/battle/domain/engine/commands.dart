import 'package:meta/meta.dart';

/// Una acción del jugador. La capa visual no modifica el estado: envía
/// comandos con `Simulation.enqueue` y la simulación los aplica al inicio
/// del tick siguiente. Con la semilla y la lista de comandos (con su tick)
/// se puede reproducir una partida completa.
///
/// Es `sealed`: si se agrega un comando, el compilador avisa dónde falta
/// manejarlo.
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

/// Construye un guardián de tipo [guardianType] en el espacio [slotId].
final class BuildGuardian extends PlayerCommand {
  const new({required this.slotId, required this.guardianType});

  final String slotId;
  final String guardianType;

  @override
  bool operator ==(Object other) =>
      other is BuildGuardian &&
      other.slotId == slotId &&
      other.guardianType == guardianType;

  @override
  int get hashCode => Object.hash(slotId, guardianType);

  @override
  String toString() => 'BuildGuardian($guardianType en $slotId)';
}

/// Mejora el guardián [guardianId] a su siguiente nivel.
final class UpgradeGuardian extends PlayerCommand {
  const new(this.guardianId);

  final int guardianId;

  @override
  bool operator ==(Object other) =>
      other is UpgradeGuardian && other.guardianId == guardianId;

  @override
  int get hashCode => Object.hash(UpgradeGuardian, guardianId);

  @override
  String toString() => 'UpgradeGuardian(#$guardianId)';
}

/// Elige la rama [branchId] de la especialización final de [guardianId].
final class SpecializeGuardian extends PlayerCommand {
  const new(this.guardianId, {required this.branchId});

  final int guardianId;
  final String branchId;

  @override
  bool operator ==(Object other) =>
      other is SpecializeGuardian &&
      other.guardianId == guardianId &&
      other.branchId == branchId;

  @override
  int get hashCode => Object.hash(guardianId, branchId);

  @override
  String toString() => 'SpecializeGuardian(#$guardianId → $branchId)';
}

/// Vende el guardián [guardianId] y libera su espacio.
final class SellGuardian extends PlayerCommand {
  const new(this.guardianId);

  final int guardianId;

  @override
  bool operator ==(Object other) =>
      other is SellGuardian && other.guardianId == guardianId;

  @override
  int get hashCode => Object.hash(SellGuardian, guardianId);

  @override
  String toString() => 'SellGuardian(#$guardianId)';
}

/// Cambia la estrategia de apuntado de [guardianId] a [strategy].
final class SetTargeting extends PlayerCommand {
  const new(this.guardianId, {required this.strategy});

  final int guardianId;
  final String strategy;

  @override
  bool operator ==(Object other) =>
      other is SetTargeting &&
      other.guardianId == guardianId &&
      other.strategy == strategy;

  @override
  int get hashCode => Object.hash(guardianId, strategy);

  @override
  String toString() => 'SetTargeting(#$guardianId → $strategy)';
}

/// Truco de desarrollo (nunca en release): quita las plagas en pantalla sin
/// dar maíz y empieza ya la siguiente oleada.
final class SkipWave extends PlayerCommand {
  const new();

  @override
  bool operator ==(Object other) => other is SkipWave;

  @override
  int get hashCode => (SkipWave).hashCode;

  @override
  String toString() => 'SkipWave';
}

/// Truco de desarrollo (nunca en release): hace aparecer [count] plagas del
/// primer tipo del nivel, una cada dos ticks y alternando caminos, para
/// medir el rendimiento con muchas plagas en pantalla.
final class StressTest extends PlayerCommand {
  const new({this.count = 150});

  final int count;

  @override
  bool operator ==(Object other) => other is StressTest && other.count == count;

  @override
  int get hashCode => Object.hash(StressTest, count);

  @override
  String toString() => 'StressTest($count)';
}
