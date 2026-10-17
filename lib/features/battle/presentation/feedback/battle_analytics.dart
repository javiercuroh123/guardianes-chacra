import 'package:guardianes_chacra/core/services/analytics_service.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/sim_time.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/simulation.dart';
import 'package:guardianes_chacra/features/battle/domain/events/sim_events.dart';

/// Los eventos de analítica de una partida, para encontrar niveles
/// demasiado difíciles. Escucha la simulación igual que `BattleFeedback` y
/// no decide nada del juego.
///
/// - `level_start`, al empezar: `level` y `extra_corn` (el maíz de un
///   anuncio).
/// - `level_complete`, al ganar: `level`, `stars`, `potatoes`, `seconds` y
///   `revived`.
/// - `level_fail`, al perder: `level`, `wave` (la oleada en que se perdió),
///   `total_waves`, `seconds` y `revived`.
///
/// Una partida revivida que se vuelve a perder anota dos `level_fail`; el
/// segundo con `revived: 1`.
class BattleAnalytics {
  new({
    required this._simulation,
    required this._analytics,
    required this._levelId,
    required this._starsFor,
    int extraCorn = 0,
  }) {
    _analytics.log('level_start', {'level': _levelId, 'extra_corn': extraCorn});
    _simulation.events
      ..on<LevelWon>(_won)
      ..on<LevelLost>(_lost);
  }

  final Simulation _simulation;
  final AnalyticsService _analytics;
  final String _levelId;

  /// Las estrellas que da terminar con tantas papas (ver `starsFor`).
  final int Function(int potatoesLeft) _starsFor;

  int get _seconds => _simulation.tick ~/ ticksPerSecond;

  // Los parámetros son números o textos: los booleanos van como 0 o 1, que
  // es lo que aceptan servicios como Firebase.
  int get _revived => _simulation.revived ? 1 : 0;

  void _won(LevelWon event) => _analytics.log('level_complete', {
    'level': _levelId,
    'stars': _starsFor(event.potatoesLeft),
    'potatoes': event.potatoesLeft,
    'seconds': _seconds,
    'revived': _revived,
  });

  void _lost(LevelLost event) => _analytics.log('level_fail', {
    'level': _levelId,
    'wave': _simulation.startedWaves,
    'total_waves': _simulation.totalWaves,
    'seconds': _seconds,
    'revived': _revived,
  });
}
