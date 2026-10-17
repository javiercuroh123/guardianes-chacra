import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/features/battle/presentation/style/battle_palette.dart';

double _contrastWithWhite(Color color) =>
    1.05 / (color.computeLuminance() + 0.05);

void main() {
  test('usa el color de los datos si lo hay', () {
    expect(colorFor('hondero', 0xFFA0522D), const Color(0xFFA0522D));
    expect(colorFor('hondero', null), colorForId('hondero'));
  });

  test('el mismo id da siempre el mismo color', () {
    expect(colorForId('gorgojo'), colorForId('gorgojo'));
  });

  test('ids distintos del contenido dan colores distintos', () {
    const ids = [
      'gorgojo', 'polilla', 'langosta', 'escarabajo', 'espiritu_helada',
      'granizo', 'granizo_chico', 'rey_gorgojo',
      'hondero', 'llama', 'tullpa', 'condor', 'pututu',
    ];

    expect(ids.map(colorForId).toSet(), hasLength(ids.length));
  });

  test('el texto blanco se lee sobre cualquier color (contraste 3:1)', () {
    // 3:1 es el mínimo para texto grande o en negrita (WCAG): las iniciales
    // de los guardianes se dibujan así.
    for (var i = 0; i < 500; i++) {
      final color = colorForId('id_$i');
      expect(
        _contrastWithWhite(color),
        greaterThanOrEqualTo(3),
        reason: 'id_$i → $color',
      );
    }
  });
}
