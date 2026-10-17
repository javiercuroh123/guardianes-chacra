import 'package:guardianes_chacra/features/content/domain/level_def.dart';

/// Los tipos de plaga que aparecen en las oleadas de [level], cada uno una
/// vez y en el orden en que llegan (por oleada y, dentro de cada oleada,
/// por el retraso de su grupo). Para la vista previa del nivel.
List<String> pestsAppearingIn(LevelDef level) {
  final seen = <String>{};
  for (final wave in level.waves) {
    // `List.sort` no es estable: si dos grupos salen a la vez, desempata
    // la posición que tienen en el JSON.
    final groups = wave.groups.indexed.toList()
      ..sort((a, b) {
        final byDelay = a.$2.delay.compareTo(b.$2.delay);
        return byDelay != 0 ? byDelay : a.$1.compareTo(b.$1);
      });
    for (final (_, group) in groups) {
      seen.add(group.pestId);
    }
  }
  return seen.toList();
}
