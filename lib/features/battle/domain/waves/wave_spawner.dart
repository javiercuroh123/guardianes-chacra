import 'package:guardianes_chacra/features/battle/domain/engine/sim_time.dart';
import 'package:guardianes_chacra/features/content/domain/level_def.dart';

/// Una plaga que debe aparecer en este tick. `wave` es el índice de la
/// oleada (desde 0).
typedef SpawnOrder = ({int wave, String pestId, String pathId});

/// Lo que ocurrió en un tick: la oleada que empezó (si alguna) y las
/// plagas que deben aparecer, en orden.
typedef SpawnerUpdate = ({int? startedWave, List<SpawnOrder> spawns});

/// Decide cuándo empieza cada oleada y en qué tick aparece cada plaga.
///
/// Solo conoce el calendario: no crea plagas ni sabe de papas o maíz. Las
/// oleadas no se superponen al aparecer: la cuenta regresiva de la
/// siguiente empieza cuando la actual terminó de aparecer.
class WaveSpawner {
  new(List<WaveDef> waves)
    : _waves = List.unmodifiable(waves),
      _countdown = waves.isEmpty ? null : secondsToTicks(waves.first.prepTime);

  final List<WaveDef> _waves;
  int _started = 0;
  int? _countdown;
  _ActiveWave? _active;

  int get totalWaves => _waves.length;

  /// Oleadas que ya empezaron (la siguiente en empezar tiene este índice).
  int get startedWaves => _started;

  /// Ticks que faltan para la siguiente oleada, o `null` si no hay ninguna
  /// esperando (una oleada está apareciendo o ya no quedan).
  int? get countdownTicks => _countdown;

  bool isFullySpawned(int waveIndex) =>
      waveIndex < _started && _active?.index != waveIndex;

  /// Empieza ya la oleada en cuenta regresiva. Devuelve los ticks que se
  /// saltó, o `null` si no había ninguna esperando.
  int? callNextWave() {
    final remaining = _countdown;
    if (remaining == null) return null;
    _startNextWave();
    return remaining;
  }

  SpawnerUpdate tick() {
    int? started;
    final countdown = _countdown;
    if (countdown != null) {
      if (countdown <= 1) {
        started = _started;
        _startNextWave();
      } else {
        _countdown = countdown - 1;
      }
    }

    final spawns = <SpawnOrder>[];
    final active = _active;
    if (active != null) {
      active.spawnDue(spawns);
      if (active.isDone) {
        _active = null;
        if (_started < _waves.length) {
          _countdown = secondsToTicks(_waves[_started].prepTime);
        }
      }
    }
    return (startedWave: started, spawns: spawns);
  }

  void _startNextWave() {
    _active = _ActiveWave(_started, _waves[_started]);
    _started++;
    _countdown = null;
  }
}

/// Avance de la oleada que está apareciendo.
class _ActiveWave {
  new(this.index, WaveDef wave)
    : _groups = [for (final group in wave.groups) _GroupCursor(group)];

  final int index;
  final List<_GroupCursor> _groups;

  /// Ticks transcurridos desde que empezó la oleada.
  int _elapsed = 0;

  bool get isDone => _groups.every((group) => group.remaining == 0);

  void spawnDue(List<SpawnOrder> out) {
    for (final cursor in _groups) {
      // `while` y no `if`: con intervalo 0 aparece todo el grupo a la vez.
      while (cursor.remaining > 0 && cursor.nextAt == _elapsed) {
        out.add((
          wave: index,
          pestId: cursor.group.pestId,
          pathId: cursor.group.pathId,
        ));
        cursor
          ..remaining -= 1
          ..nextAt += cursor.interval;
      }
    }
    _elapsed++;
  }
}

class _GroupCursor {
  new(this.group)
    : remaining = group.count,
      nextAt = secondsToTicks(group.delay),
      interval = secondsToTicks(group.interval);

  final SpawnGroupDef group;
  final int interval;
  int remaining;
  int nextAt;
}
