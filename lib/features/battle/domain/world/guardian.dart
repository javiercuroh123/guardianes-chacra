import 'package:guardianes_chacra/core/math/vec2.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/attacks/guardian_behavior.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/targeting/targeting_strategies.dart';
import 'package:guardianes_chacra/features/content/domain/guardian_def.dart';
import 'package:guardianes_chacra/features/content/domain/pest_def.dart';

/// Lo que las demás capas pueden leer de un guardián.
abstract interface class GuardianView {
  int get id;
  GuardianDef get def;
  String get slotId;
  Vec2 get position;

  /// Nivel desde 1. La especialización es `def.levels.length + 1`.
  int get level;

  /// Rama elegida en la especialización, o `null` si todavía no.
  String? get branchId;

  String get targetingId;

  /// Alcance en casillas del nivel actual.
  double get range;

  /// 1 = normal. Las auras lo suben (1,25 = ataca un 25 % más rápido).
  double get attackSpeedMultiplier;

  /// Maíz gastado en total (construcción y mejoras); define la venta.
  int get totalSpent;
}

/// Un guardián construido. Solo la simulación lo modifica.
class Guardian implements GuardianView {
  new({
    required this.id,
    required this.def,
    required this.slotId,
    required this.position,
    required this.targeting,
    required this.targetingId,
    required this.behaviors,
    required this.totalSpent,
  });

  @override
  final int id;

  @override
  final GuardianDef def;

  @override
  final String slotId;

  @override
  final Vec2 position;

  /// Índice en `def.levels` mientras no se especializa.
  int levelIndex = 0;

  GuardianBranchDef? branch;

  /// Comportamientos del nivel actual (se recrean al mejorar).
  List<GuardianBehavior> behaviors;

  TargetingStrategy targeting;

  @override
  String targetingId;

  @override
  double attackSpeedMultiplier = 1;

  @override
  int totalSpent;

  GuardianLevelDef get stats => branch?.level ?? def.levels[levelIndex];

  @override
  int get level => branch != null ? def.levels.length + 1 : levelIndex + 1;

  @override
  String? get branchId => branch?.id;

  @override
  double get range => stats.range;

  Set<PestTag> get targets => stats.targets;
}
