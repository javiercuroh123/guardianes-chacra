import 'package:guardianes_chacra/core/math/vec2.dart';
import 'package:guardianes_chacra/features/content/domain/battle_rules.dart';
import 'package:guardianes_chacra/features/content/domain/behavior_spec.dart';
import 'package:guardianes_chacra/features/content/domain/guardian_def.dart';
import 'package:guardianes_chacra/features/content/domain/level_def.dart';
import 'package:guardianes_chacra/features/content/domain/pest_def.dart';

/// Datos de prueba para la simulación. Los JSON reales llegan en la Fase 4;
/// estos valores están elegidos para que las cuentas se hagan a mano.

const testRules = BattleRules(
  sellRefundRate: 0.7,
  minDamageFraction: 0.2,
  twoStarsFraction: 0.5,
  threeStarsFraction: 0.9,
);

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

/// Blanco de práctica: no se mueve y aguanta mucho. Sirve para contar
/// golpes sin que llegue a la collca.
const blanco = PestDef(
  id: 'blanco',
  maxHealth: 100,
  speed: 0,
  cornReward: 1,
  potatoDamage: 1,
  tags: {PestTag.ground},
);

const Map<String, PestDef> pestCatalog = {
  'gorgojo': gorgojo,
  'polilla': polilla,
  'blanco': blanco,
};

/// Camino recto de 10 casillas; la collca está en (10, 0).
const straightPath = PathDef(id: 'recto', points: [Vec2(0, 0), Vec2(10, 0)]);

/// Dos espacios junto al camino recto, a una casilla de él.
const testSlots = [
  BuildSlotDef(id: 'a', position: Vec2(5, 1)),
  BuildSlotDef(id: 'b', position: Vec2(5, -1)),
];

BehaviorSpec stone(double damage, {double cooldown = 1}) =>
    BehaviorSpec('projectile', {
      'damage': damage,
      'damageType': 'physical',
      'cooldown': cooldown,
      // 30 casillas/s = 1 por tick: llega casi al instante.
      'projectileSpeed': 30,
    });

/// Hondero de prueba: cada nivel tiene otro alcance para notar el cambio.
final hondero = GuardianDef(
  id: 'hondero',
  levels: [
    GuardianLevelDef(
      cost: 50,
      range: 3,
      targets: const {PestTag.ground, PestTag.flying},
      behaviors: [stone(5)],
    ),
    GuardianLevelDef(
      cost: 40,
      range: 3.5,
      targets: const {PestTag.ground, PestTag.flying},
      behaviors: [stone(8)],
    ),
    GuardianLevelDef(
      cost: 60,
      range: 4,
      targets: const {PestTag.ground, PestTag.flying},
      behaviors: [stone(12)],
    ),
  ],
  branches: [
    GuardianBranchDef(
      id: 'piedra_pesada',
      level: GuardianLevelDef(
        cost: 100,
        range: 4.5,
        targets: const {PestTag.ground, PestTag.flying},
        behaviors: [stone(20)],
      ),
    ),
    GuardianBranchDef(
      id: 'honda_rapida',
      level: GuardianLevelDef(
        cost: 90,
        range: 5,
        targets: const {PestTag.ground, PestTag.flying},
        behaviors: [stone(12, cooldown: 0.5)],
      ),
    ),
  ],
);

/// Un guardián de un solo nivel que cuesta 75 (su venta da 52,5 → 52).
final espantapajaros = GuardianDef(
  id: 'espantapajaros',
  levels: [
    GuardianLevelDef(
      cost: 75,
      range: 2,
      targets: const {PestTag.ground},
      behaviors: [stone(1)],
    ),
  ],
);

final Map<String, GuardianDef> guardianCatalog = {
  'hondero': hondero,
  'espantapajaros': espantapajaros,
};

/// Un nivel con el camino recto, [corn] de maíz y 2 de maíz por segundo
/// saltado al llamar una oleada antes de tiempo.
LevelDef testLevel({
  required List<WaveDef> waves,
  int potatoes = 10,
  int corn = 100,
  List<PathDef> paths = const [straightPath],
  List<BuildSlotDef> slots = testSlots,
}) => LevelDef(
  id: 'prueba',
  mapFile: 'prueba.tmx',
  map: MapDef(
    width: 12,
    height: 6,
    collca: const Vec2(10, 0),
    paths: paths,
    buildSlots: slots,
  ),
  startingCorn: corn,
  startingPotatoes: potatoes,
  earlyCallCornPerSecond: 2,
  waves: waves,
);

/// Una oleada de [count] plagas de [pestId] por [pathId], separadas por
/// [interval] segundos.
WaveDef testWave(
  String pestId, {
  int count = 1,
  double prepTime = 1,
  double interval = 1,
  int reward = 10,
  String pathId = 'recto',
}) => WaveDef(
  prepTime: prepTime,
  reward: reward,
  groups: [
    SpawnGroupDef(
      pestId: pestId,
      count: count,
      interval: interval,
      pathId: pathId,
    ),
  ],
);
