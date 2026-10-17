import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/stars.dart';

import '../../../../helpers/battle_fixtures.dart';

void main() {
  // testRules: dos estrellas desde el 50 % y tres desde el 90 %.
  for (final (potatoes, stars) in [
    (20, 3),
    (18, 3),
    (17, 2),
    (10, 2),
    (9, 1),
    (1, 1),
    (0, 0),
  ]) {
    test('con $potatoes de 20 papas, $stars estrellas', () {
      expect(
        starsFor(
          potatoesLeft: potatoes,
          startingPotatoes: 20,
          rules: testRules,
        ),
        stars,
      );
    });
  }
}
