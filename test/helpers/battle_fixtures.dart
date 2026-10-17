import 'package:guardianes_chacra/core/math/vec2.dart';
import 'package:guardianes_chacra/features/content/domain/level_def.dart';
import 'package:guardianes_chacra/features/content/domain/pest_def.dart';

/// Datos de prueba para la simulación. Los JSON reales llegan en la Fase 4;
/// estos valores están elegidos para que las cuentas se hagan a mano.

/// 2 casillas/s: recorre el camino recto (10 casillas) en 5 s = 150 ticks.
const gorgojo = PestDef(
  id: 'gorgojo',
  maxHealth: 10,
  speed: 2,
  cornReward: 5,
  potatoDamage: 1,
  tags: {PestTag.ground},
);

/// 5 casillas/s: recorre el camino recto en 2 s = 60 ticks.
const polilla = PestDef(
  id: 'polilla',
  maxHealth: 4,
  speed: 5,
  cornReward: 3,
  potatoDamage: 2,
  tags: {PestTag.flying},
);

const Map<String, PestDef> pestCatalog = {
  'gorgojo': gorgojo,
  'polilla': polilla,
};

/// Camino recto de 10 casillas; la collca está en (10, 0).
const straightPath = PathDef(id: 'recto', points: [Vec2(0, 0), Vec2(10, 0)]);

/// Un nivel con el camino recto, 100 de maíz y 2 de maíz por segundo
/// saltado al llamar una oleada antes de tiempo.
LevelDef testLevel({required List<WaveDef> waves, int potatoes = 10}) =>
    LevelDef(
      startingCorn: 100,
      startingPotatoes: potatoes,
      earlyCallCornPerSecond: 2,
      paths: const [straightPath],
      waves: waves,
    );

/// Una oleada de [count] plagas de [pestId] por el camino recto, separadas
/// por [interval] segundos.
WaveDef testWave(
  String pestId, {
  int count = 1,
  double prepTime = 1,
  double interval = 1,
  int reward = 10,
}) => WaveDef(
  prepTime: prepTime,
  reward: reward,
  groups: [
    SpawnGroupDef(
      pestId: pestId,
      count: count,
      interval: interval,
      pathId: straightPath.id,
    ),
  ],
);
