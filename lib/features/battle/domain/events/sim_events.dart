import 'package:guardianes_chacra/features/battle/domain/engine/commands.dart';
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

/// Por qué no se pudo aplicar un comando.
enum RejectionReason {
  /// Se pidió la siguiente oleada, pero no hay ninguna en cuenta regresiva.
  noWaveWaiting,
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
