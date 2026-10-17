import 'package:guardianes_chacra/core/math/vec2.dart';
import 'package:guardianes_chacra/features/content/domain/unlock_rule.dart';
import 'package:meta/meta.dart';

/// Un nivel: su JSON (`assets/content/levels/<id>.json`) más su mapa de
/// Tiled.
@immutable
class LevelDef {
  const new({
    required this.id,
    required this.mapFile,
    required this.map,
    required this.startingCorn,
    required this.startingPotatoes,
    required this.earlyCallCornPerSecond,
    required this.waves,
    this.unlock = UnlockRule.always,
    this.music,
  });

  final String id;

  /// Nombre del archivo del mapa dentro de `assets/tiles/`.
  final String mapFile;

  final MapDef map;
  final int startingCorn;
  final int startingPotatoes;

  /// Maíz por cada segundo de cuenta regresiva que el jugador se salta al
  /// llamar la siguiente oleada antes de tiempo.
  final double earlyCallCornPerSecond;

  final List<WaveDef> waves;

  /// Qué hace falta para poder jugarlo.
  final UnlockRule unlock;

  /// Música del nivel, relativa a `assets/audio/` (sin ella, silencio).
  final String? music;
}

/// Lo que la simulación necesita del mapa de Tiled, en casillas.
@immutable
class MapDef {
  const new({
    required this.width,
    required this.height,
    required this.collca,
    required this.paths,
    this.buildSlots = const [],
  });

  /// Tamaño en casillas.
  final int width;
  final int height;

  final Vec2 collca;
  final List<PathDef> paths;

  /// Espacios fijos donde se puede construir un guardián.
  final List<BuildSlotDef> buildSlots;
}

/// Un espacio de construcción del mapa.
@immutable
class BuildSlotDef {
  const new({required this.id, required this.position});

  final String id;

  /// En casillas del mapa.
  final Vec2 position;
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
