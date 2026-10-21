import 'package:guardianes_chacra/features/content/domain/game_content.dart';
import 'package:guardianes_chacra/features/content/domain/unlock_rule.dart';
import 'package:guardianes_chacra/features/progress/domain/progress.dart';
import 'package:meta/meta.dart';

/// Lo que se abrió recién al anotar un resultado (ids, en el orden del
/// contenido).
typedef Unlocked = ({List<String> levels, List<String> guardians});

/// Las reglas de desbloqueo del contenido aplicadas al avance del jugador.
///
/// Algo está abierto si ya se abrió antes (queda guardado en [Progress]) o
/// si hoy cumple su regla. Así, si una actualización endurece una regla, el
/// jugador no pierde lo que ya tenía; si la relaja, se abre solo.
@immutable
class Progression {
  const new({required this.levels, required this.guardians});

  factory of(GameContent content) => Progression(
    levels: {for (final level in content.levels) level.id: level.unlock},
    guardians: {
      for (final guardian in content.guardians.values)
        guardian.id: guardian.unlock,
    },
  );

  /// Reglas por id, en el orden del contenido.
  final Map<String, UnlockRule> levels;
  final Map<String, UnlockRule> guardians;

  bool canPlay(Progress progress, String levelId) =>
      progress.unlockedLevels.contains(levelId) ||
      (levels[levelId]?.isMetBy(progress.stars) ?? false);

  /// El nivel que conviene jugar ahora: el primero abierto sin estrellas;
  /// si todos los abiertos están ganados, el que tiene menos (el primero
  /// si empatan), para juntar las que faltan; con todos en 3 estrellas, el
  /// último abierto. Con [unlockAll] cuenta todos como abiertos. `null` si
  /// no hay ninguno abierto.
  String? suggested(Progress progress, {bool unlockAll = false}) {
    final open = [
      for (final id in levels.keys)
        if (unlockAll || canPlay(progress, id)) id,
    ];
    if (open.isEmpty) return null;
    var best = open.first;
    for (final id in open) {
      if (progress.starsOf(id) < progress.starsOf(best)) best = id;
    }
    return progress.starsOf(best) >= 3 ? open.last : best;
  }

  bool canBuild(Progress progress, String guardianId) =>
      progress.unlockedGuardians.contains(guardianId) ||
      (guardians[guardianId]?.isMetBy(progress.stars) ?? false);

  /// Anota un resultado y deja guardado todo lo que queda abierto. También
  /// devuelve lo que se abrió recién, para contarlo en la victoria.
  (Progress, Unlocked) record(
    Progress progress,
    String levelId, {
    required int stars,
  }) {
    final after = progress.withResult(levelId, stars: stars);
    final openLevels = [
      for (final id in levels.keys)
        if (canPlay(after, id)) id,
    ];
    final openGuardians = [
      for (final id in guardians.keys)
        if (canBuild(after, id)) id,
    ];
    return (
      after.withUnlocked(levels: openLevels, guardians: openGuardians),
      (
        levels: [
          for (final id in openLevels)
            if (!canPlay(progress, id)) id,
        ],
        guardians: [
          for (final id in openGuardians)
            if (!canBuild(progress, id)) id,
        ],
      ),
    );
  }
}
