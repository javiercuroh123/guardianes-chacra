import 'package:guardianes_chacra/core/math/vec2.dart';
import 'package:meta/meta.dart';

/// Un nivel tal como lo necesita la simulación. En la Fase 4 se arma a
/// partir del JSON del nivel y su mapa de Tiled.
@immutable
class LevelDef {
  const new({
    required this.startingCorn,
    required this.startingPotatoes,
    required this.earlyCallCornPerSecond,
    required this.paths,
    required this.waves,
  });

  final int startingCorn;
  final int startingPotatoes;

  /// Maíz por cada segundo de cuenta regresiva que el jugador se salta al
  /// llamar la siguiente oleada antes de tiempo.
  final double earlyCallCornPerSecond;

  final List<PathDef> paths;
  final List<WaveDef> waves;
}

/// Camino que siguen las plagas, de la entrada a la collca.
@immutable
class PathDef {
  const new({required this.id, required this.points});

  final String id;

  /// Puntos en casillas del mapa. El último es la collca.
  final List<Vec2> points;
}

@immutable
class WaveDef {
  const new({
    required this.prepTime,
    required this.reward,
    required this.groups,
  });

  /// Segundos de cuenta regresiva antes de que empiece. Para la primera
  /// oleada se cuentan desde el inicio del nivel; para las demás, desde que
  /// terminó de aparecer la oleada anterior.
  final double prepTime;

  /// Maíz que se gana al completarla (todas sus plagas aparecieron y ya no
  /// queda ninguna).
  final int reward;

  final List<SpawnGroupDef> groups;
}

/// Un grupo de plagas iguales que entran por el mismo camino.
@immutable
class SpawnGroupDef {
  const new({
    required this.pestId,
    required this.count,
    required this.pathId,
    this.delay = 0,
    this.interval = 0,
  });

  final String pestId;
  final int count;
  final String pathId;

  /// Segundos desde que empieza la oleada hasta la primera plaga del grupo.
  final double delay;

  /// Segundos entre una plaga del grupo y la siguiente.
  final double interval;
}
