import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/features/battle/presentation/style/battle_colors.dart';

/// Contraste entre dos colores según WCAG (de 1:1 a 21:1).
double _contrast(Color a, Color b) {
  final (la, lb) = (a.computeLuminance(), b.computeLuminance());
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Los suelos del mapa (de `tool/generate_placeholder_tileset.py`): por
/// encima de ellos se dibujan las plagas, sus efectos y los números.
const _grounds = {
  'pasto': Color(0xFF6AB04C),
  'pasto oscuro': Color(0xFF56963C),
  'tierra': Color(0xFFC4A06C),
  'tierra oscura': Color(0xFFA08054),
  'agua': Color(0xFF4A90C2),
  'agua clara': Color(0xFF82BAE2),
  'andén': Color(0xFF967654),
  'roca': Color(0xFF8C8C8C),
  'espacio': Color(0xFFE8CC80),
};

/// Una marca en dos tonos se lee si sus tonos contrastan entre sí y, sobre
/// cada suelo, al menos uno contrasta con él. 3:1 es el mínimo de WCAG
/// para gráficos y texto grande (los números de daño son de 30 px en
/// negrita).
void _expectReadable(String name, Color fill, Color border) {
  expect(
    _contrast(fill, border),
    greaterThanOrEqualTo(3),
    reason: '$name contra su borde',
  );
  for (final MapEntry(key: ground, value: color) in _grounds.entries) {
    final best = math.max(_contrast(fill, color), _contrast(border, color));
    expect(best, greaterThanOrEqualTo(3), reason: '$name sobre $ground');
  }
}

void main() {
  test('las marcas de efectos se leen sobre cualquier suelo', () {
    _expectReadable('lento', BattleColors.slow, BattleColors.effectBorder);
    _expectReadable('quemadura', BattleColors.burn, BattleColors.effectBorder);
    _expectReadable('aturdido', BattleColors.stun, BattleColors.effectBorder);
  });

  test('los números de daño se leen sobre cualquier suelo', () {
    _expectReadable('daño', BattleColors.damageText, BattleColors.effectBorder);
  });

  test('sin el borde, el color solo no alcanzaría sobre la tierra', () {
    // Por eso las marcas llevan borde: el celeste de lento casi no
    // contrasta con el camino.
    expect(_contrast(BattleColors.slow, _grounds['tierra']!), lessThan(3));
  });
}
