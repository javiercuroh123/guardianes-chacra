import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/app/app_theme.dart';

/// Contraste según WCAG: (más clara + 0,05) / (más oscura + 0,05).
double _contrast(Color a, Color b) {
  final (la, lb) = (a.computeLuminance(), b.computeLuminance());
  return la > lb ? (la + 0.05) / (lb + 0.05) : (lb + 0.05) / (la + 0.05);
}

void main() {
  final scheme = AppTheme.light.colorScheme;
  final game = AppTheme.light.extension<GameColors>()!;

  // WCAG AA: 4,5:1 para texto normal; 3:1 para íconos y texto grande.
  for (final (name, foreground, background, minimum) in [
    ('texto sobre el primario', scheme.onPrimary, scheme.primary, 4.5),
    ('texto sobre el secundario', scheme.onSecondary, scheme.secondary, 4.5),
    ('texto sobre el terciario', scheme.onTertiary, scheme.tertiary, 4.5),
    ('texto sobre el fondo', scheme.onSurface, scheme.surface, 4.5),
    // El HUD es casi opaco: se mide contra su color sin transparencia.
    ('texto del HUD', game.onHud, game.hud.withValues(alpha: 1), 4.5),
    (
      'bono de maíz en el HUD',
      scheme.secondary,
      game.hud.withValues(alpha: 1),
      4.5,
    ),
    ('estrella ganada sobre el fondo', game.star, scheme.surface, 3.0),
    // Lo desbloqueado en la tarjeta de victoria.
    ('texto terciario sobre el fondo', scheme.tertiary, scheme.surface, 4.5),
  ]) {
    test('contraste suficiente: $name', () {
      expect(_contrast(foreground, background), greaterThanOrEqualTo(minimum));
    });
  }
}
