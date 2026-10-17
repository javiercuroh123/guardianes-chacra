import 'package:guardianes_chacra/features/content/domain/behavior_spec.dart';
import 'package:guardianes_chacra/features/content/domain/pest_def.dart';
import 'package:guardianes_chacra/features/content/domain/sprite_def.dart';
import 'package:guardianes_chacra/features/content/domain/unlock_rule.dart';
import 'package:meta/meta.dart';

/// Definición de un tipo de guardián, tal como viene de los datos.
///
/// Camino de mejoras: `levels[0]` se construye, los siguientes son las
/// mejoras en orden y, después de la última, se elige una de las
/// [branches] (la especialización final).
@immutable
class GuardianDef {
  const new({
    required this.id,
    required this.levels,
    this.branches = const [],
    this.defaultTargeting = 'first',
    this.color,
    this.unlock = UnlockRule.always,
    this.sprite,
  });

  final String id;
  final List<GuardianLevelDef> levels;
  final List<GuardianBranchDef> branches;

  /// Estrategia de apuntado con la que se construye (el jugador la cambia).
  final String defaultTargeting;

  /// Color de reemplazo para dibujarlo (ARGB) mientras no tenga imagen.
  /// Si falta, la vista usa uno derivado de su id.
  final int? color;

  /// Qué hace falta para poder construirlo.
  final UnlockRule unlock;

  /// Imagen del guardián; cada nivel o rama puede cambiarla.
  final SpriteDef? sprite;

  /// La imagen en el [level] dado (desde 1) o con la rama [branchId]: la
  /// de ese nivel o rama si tiene una, si no la del guardián.
  SpriteDef? spriteAt({required int level, String? branchId}) {
    final branch = branches.where((branch) => branch.id == branchId);
    final stats = branch.isEmpty ? levels[level - 1] : branch.first.level;
    return stats.sprite ?? sprite;
  }
}

/// Las estadísticas completas de un nivel (no las diferencias con el
/// anterior): así cada nivel se lee y se balancea por sí solo.
@immutable
class GuardianLevelDef {
  const new({
    required this.cost,
    required this.range,
    required this.targets,
    required this.behaviors,
    this.sprite,
  });

  /// Maíz para construir (primer nivel) o para mejorar a este nivel.
  final int cost;

  /// Alcance en casillas.
  final double range;

  /// Etiquetas de las plagas a las que puede atacar.
  final Set<PestTag> targets;

  /// Ataques o auras de este nivel, creados por el registro.
  final List<BehaviorSpec> behaviors;

  /// Imagen propia de este nivel o rama (si no, la del guardián).
  final SpriteDef? sprite;
}

/// Una rama de la especialización final.
@immutable
class GuardianBranchDef {
  const new({required this.id, required this.level});

  final String id;
  final GuardianLevelDef level;
}
