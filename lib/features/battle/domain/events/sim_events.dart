import 'package:guardianes_chacra/core/math/vec2.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/commands.dart';
import 'package:guardianes_chacra/features/content/domain/pest_def.dart';
import 'package:meta/meta.dart';

/// Algo que ocurrió en la simulación. Se publica en el bus de eventos en el
/// mismo tick en que ocurre; los gráficos, el audio, los logros o la
/// analítica se suscriben a los que les interesan.
///
/// Es `sealed`: un `switch` sobre un [SimEvent] obliga a manejar todos los
/// tipos. [tick] es el tick en que ocurrió.
@immutable
sealed class SimEvent {
  const new(this.tick);

  final int tick;

  String get _name;
  List<Object?> get _fields;

  @override
  bool operator ==(Object other) =>
      other is SimEvent &&
      other._name == _name &&
      other.tick == tick &&
      _sameFields(other._fields, _fields);

  @override
  int get hashCode => Object.hash(_name, tick, Object.hashAll(_fields));

  @override
  String toString() => '$_name@$tick(${_fields.join(', ')})';

  static bool _sameFields(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Empezó la oleada [waveNumber] (contando desde 1).
final class WaveStarted extends SimEvent {
  const new(super.tick, {required this.waveNumber, required this.calledEarly});

  final int waveNumber;

  /// El jugador la llamó antes de que terminara la cuenta regresiva.
  final bool calledEarly;

  @override
  String get _name => 'WaveStarted';

  @override
  List<Object?> get _fields => [waveNumber, calledEarly];
}

/// Apareció la plaga [pestId], del tipo [pestType], al inicio de [pathId].
final class PestSpawned extends SimEvent {
  const new(
    super.tick, {
    required this.pestId,
    required this.pestType,
    required this.pathId,
  });

  final int pestId;
  final String pestType;
  final String pathId;

  @override
  String get _name => 'PestSpawned';

  @override
  List<Object?> get _fields => [pestId, pestType, pathId];
}

/// La plaga [pestId] llegó a la collca, se comió [potatoesLost] papas y
/// desapareció.
final class CollcaDamaged extends SimEvent {
  const new(
    super.tick, {
    required this.pestId,
    required this.potatoesLost,
    required this.potatoesLeft,
  });

  final int pestId;
  final int potatoesLost;
  final int potatoesLeft;

  @override
  String get _name => 'CollcaDamaged';

  @override
  List<Object?> get _fields => [pestId, potatoesLost, potatoesLeft];
}

/// Todas las plagas de la oleada [waveNumber] aparecieron y ya no queda
/// ninguna. El jugador gana [reward] de maíz.
final class WaveCompleted extends SimEvent {
  const new(super.tick, {required this.waveNumber, required this.reward});

  final int waveNumber;
  final int reward;

  @override
  String get _name => 'WaveCompleted';

  @override
  List<Object?> get _fields => [waveNumber, reward];
}

/// El maíz cambió en [delta]; ahora hay [total].
final class CornChanged extends SimEvent {
  const new(super.tick, {required this.delta, required this.total});

  final int delta;
  final int total;

  @override
  String get _name => 'CornChanged';

  @override
  List<Object?> get _fields => [delta, total];
}

/// Se completaron todas las oleadas y quedan [potatoesLeft] papas.
final class LevelWon extends SimEvent {
  const new(super.tick, {required this.potatoesLeft});

  final int potatoesLeft;

  @override
  String get _name => 'LevelWon';

  @override
  List<Object?> get _fields => [potatoesLeft];
}

/// Las papas llegaron a 0.
final class LevelLost extends SimEvent {
  const new(super.tick);

  @override
  String get _name => 'LevelLost';

  @override
  List<Object?> get _fields => const [];
}

/// Se construyó el guardián [guardianId] en el espacio [slotId].
final class GuardianBuilt extends SimEvent {
  const new(
    super.tick, {
    required this.guardianId,
    required this.guardianType,
    required this.slotId,
  });

  final int guardianId;
  final String guardianType;
  final String slotId;

  @override
  String get _name => 'GuardianBuilt';

  @override
  List<Object?> get _fields => [guardianId, guardianType, slotId];
}

/// El guardián [guardianId] subió al nivel [level] (contando desde 1).
final class GuardianUpgraded extends SimEvent {
  const new(super.tick, {required this.guardianId, required this.level});

  final int guardianId;
  final int level;

  @override
  String get _name => 'GuardianUpgraded';

  @override
  List<Object?> get _fields => [guardianId, level];
}

/// El guardián [guardianId] eligió la rama [branchId].
final class GuardianSpecialized extends SimEvent {
  const new(super.tick, {required this.guardianId, required this.branchId});

  final int guardianId;
  final String branchId;

  @override
  String get _name => 'GuardianSpecialized';

  @override
  List<Object?> get _fields => [guardianId, branchId];
}

/// Se vendió el guardián [guardianId] por [refund] de maíz.
final class GuardianSold extends SimEvent {
  const new(super.tick, {required this.guardianId, required this.refund});

  final int guardianId;
  final int refund;

  @override
  String get _name => 'GuardianSold';

  @override
  List<Object?> get _fields => [guardianId, refund];
}

/// El guardián [guardianId] ahora apunta con la estrategia [strategy].
final class TargetingChanged extends SimEvent {
  const new(super.tick, {required this.guardianId, required this.strategy});

  final int guardianId;
  final String strategy;

  @override
  String get _name => 'TargetingChanged';

  @override
  List<Object?> get _fields => [guardianId, strategy];
}

/// El guardián [guardianId] lanzó el proyectil [projectileId] hacia la
/// plaga [pestId] (la capa visual lo gira hacia ella).
final class GuardianFired extends SimEvent {
  const new(
    super.tick, {
    required this.guardianId,
    required this.pestId,
    required this.projectileId,
  });

  final int guardianId;
  final int pestId;
  final int projectileId;

  @override
  String get _name => 'GuardianFired';

  @override
  List<Object?> get _fields => [guardianId, pestId, projectileId];
}

/// El guardián [guardianId] lanzó un ataque en área a su alrededor.
final class AreaPulsed extends SimEvent {
  const new(super.tick, {required this.guardianId});

  final int guardianId;

  @override
  String get _name => 'AreaPulsed';

  @override
  List<Object?> get _fields => [guardianId];
}

/// El proyectil [projectileId] impactó en [position] y desapareció.
final class ProjectileImpacted extends SimEvent {
  const new(super.tick, {required this.projectileId, required this.position});

  final int projectileId;
  final Vec2 position;

  @override
  String get _name => 'ProjectileImpacted';

  @override
  List<Object?> get _fields => [projectileId, position];
}

/// La plaga [pestId] recibió [amount] de daño de tipo [damageType] (ya
/// descontadas su armadura y sus resistencias).
final class PestDamaged extends SimEvent {
  const new(
    super.tick, {
    required this.pestId,
    required this.amount,
    required this.damageType,
  });

  final int pestId;
  final double amount;
  final DamageType damageType;

  @override
  String get _name => 'PestDamaged';

  @override
  List<Object?> get _fields => [pestId, amount, damageType];
}

/// La plaga [pestId] fue derrotada y el jugador ganó [reward] de maíz.
final class PestDefeated extends SimEvent {
  const new(
    super.tick, {
    required this.pestId,
    required this.pestType,
    required this.reward,
  });

  final int pestId;
  final String pestType;
  final int reward;

  @override
  String get _name => 'PestDefeated';

  @override
  List<Object?> get _fields => [pestId, pestType, reward];
}

/// Por qué no se pudo aplicar un comando.
enum RejectionReason {
  /// Se pidió la siguiente oleada, pero no hay ninguna en cuenta regresiva.
  noWaveWaiting,

  /// No alcanza el maíz.
  notEnoughCorn,

  /// El espacio de construcción no existe en el nivel.
  unknownSlot,

  /// Ya hay un guardián en ese espacio.
  slotOccupied,

  /// No existe ese tipo de guardián.
  unknownGuardianType,

  /// No hay ningún guardián con ese id (quizás se vendió).
  guardianNotFound,

  /// Ya pasó todas las mejoras: falta elegir una rama.
  chooseBranch,

  /// Ya no tiene más mejoras.
  maxLevel,

  /// Todavía no llegó a la última mejora, o ya eligió una rama.
  cannotSpecialize,

  /// Esa rama no existe para este guardián.
  unknownBranch,

  /// No existe esa estrategia de apuntado.
  unknownTargeting,
}

/// El comando [command] no se aplicó por [reason]. La interfaz puede
/// mostrar un aviso en lugar de fallar en silencio.
final class CommandRejected extends SimEvent {
  const new(super.tick, {required this.command, required this.reason});

  final PlayerCommand command;
  final RejectionReason reason;

  @override
  String get _name => 'CommandRejected';

  @override
  List<Object?> get _fields => [command, reason];
}
