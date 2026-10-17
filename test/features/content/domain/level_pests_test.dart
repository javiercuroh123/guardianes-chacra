import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/features/content/domain/level_def.dart';
import 'package:guardianes_chacra/features/content/domain/level_pests.dart';

import '../../../helpers/battle_fixtures.dart';

void main() {
  test('lista cada plaga una vez, en el orden en que llega', () {
    final level = testLevel(
      waves: const [
        WaveDef(
          prepTime: 1,
          reward: 0,
          groups: [
            // La polilla llega después aunque esté primero en el JSON.
            SpawnGroupDef(
              pestId: 'polilla',
              count: 2,
              delay: 5,
              pathId: 'recto',
            ),
            SpawnGroupDef(pestId: 'gorgojo', count: 3, pathId: 'recto'),
          ],
        ),
        WaveDef(
          prepTime: 1,
          reward: 0,
          groups: [
            SpawnGroupDef(pestId: 'gorgojo', count: 1, pathId: 'recto'),
            SpawnGroupDef(pestId: 'blanco', count: 1, pathId: 'recto'),
          ],
        ),
      ],
    );

    expect(pestsAppearingIn(level), ['gorgojo', 'polilla', 'blanco']);
  });

  test('si muchos grupos salen a la vez, respeta el orden del JSON', () {
    // Con 100 grupos simultáneos (más de 32, cuando Dart deja de ordenar
    // por inserción), un ordenamiento inestable los mezclaría.
    final ids = [for (var i = 0; i < 100; i++) 'plaga_$i'];
    final level = testLevel(
      waves: [
        WaveDef(
          prepTime: 1,
          reward: 0,
          groups: [
            for (final id in ids)
              SpawnGroupDef(pestId: id, count: 1, pathId: 'recto'),
          ],
        ),
      ],
    );

    expect(pestsAppearingIn(level), ids);
  });
}
