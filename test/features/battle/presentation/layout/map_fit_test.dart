import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/features/battle/presentation/layout/map_fit.dart';

void main() {
  // Un mapa de 26 × 12 casillas de 64 px.
  const map = Size(1664, 768);

  test('en un teléfono horizontal manda la altura', () {
    // Redmi Note 14 Pro en horizontal: 853 × 384 dp.
    final fit = MapFit.compute(map: map, viewport: const Size(853, 384));

    expect(fit.zoom, 0.5);
    // Sobran 853 − 832 = 21 dp: 10,5 a cada lado.
    expect(fit.origin, const Offset(10.5, 0));
  });

  test('en una tablet 4:3 manda el ancho y sobra arriba y abajo', () {
    final fit = MapFit.compute(map: map, viewport: const Size(1024, 768));

    expect(fit.zoom, closeTo(1024 / 1664, 1e-9));
    final drawnHeight = 768 * fit.zoom;
    expect(fit.origin.dx, 0);
    expect(fit.origin.dy, closeTo((768 - drawnHeight) / 2, 1e-9));
  });

  test('toScreen lleva un punto del mapa a la pantalla', () {
    final fit = MapFit.compute(map: map, viewport: const Size(853, 384));

    expect(fit.toScreen(Offset.zero), const Offset(10.5, 0));
    expect(fit.toScreen(const Offset(832, 384)), const Offset(426.5, 192));
    expect(fit.toScreen(const Offset(1664, 768)), const Offset(842.5, 384));
  });
}
