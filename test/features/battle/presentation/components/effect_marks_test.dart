import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/features/battle/presentation/components/effect_marks.dart';

void main() {
  final marks = EffectMarks(
    center: const Offset(18, 18),
    radius: 18,
    headY: -16,
  );

  test('lento es un anillo punteado', () {
    final dashes = marks.slow.computeMetrics().toList();

    expect(dashes, hasLength(EffectMarks.dashes));
    expect(dashes.every((dash) => !dash.isClosed), isTrue);
  });

  test('quemadura es una corona cerrada de puntas, fuera del anillo', () {
    final crown = marks.burn.computeMetrics().single;

    expect(crown.isClosed, isTrue);
    // No se pisa con el anillo de lento cuando hay los dos efectos.
    expect(
      marks.burn.getBounds().width,
      greaterThan(marks.slow.getBounds().width + 6),
    );
  });

  test('los puntos de aturdido giran sobre la cabeza', () {
    final start = [for (var i = 0; i < 3; i++) marks.stunDot(i, 0)];
    final later = [for (var i = 0; i < 3; i++) marks.stunDot(i, 0.3)];

    expect(start.toSet(), hasLength(3));
    for (var i = 0; i < 3; i++) {
      expect(later[i], isNot(start[i]));
      // Siempre por encima del cuerpo (que empieza en y = 0).
      expect(start[i].dy, lessThan(0));
      expect(later[i].dy, lessThan(0));
    }
    // Una vuelta completa los deja donde estaban.
    expect(
      marks.stunDot(0, EffectMarks.stunTurnSeconds).dx,
      closeTo(start[0].dx, 1e-9),
    );
  });

  test('los puntos de aturdido no se tapan entre sí en toda la vuelta', () {
    // El de una plaga chica (vuela, radio 0,26 casillas): la órbita más
    // angosta.
    const radius = 0.26 * 64;
    final small = EffectMarks(
      center: const Offset(radius, radius),
      radius: radius,
      headY: -20,
    );
    for (var step = 0; step < 60; step++) {
      final seconds = EffectMarks.stunTurnSeconds * step / 60;
      final dots = [for (var i = 0; i < 3; i++) small.stunDot(i, seconds)];
      for (var a = 0; a < 3; a++) {
        for (var b = a + 1; b < 3; b++) {
          expect(
            (dots[a] - dots[b]).distance,
            greaterThanOrEqualTo(2 * EffectMarks.stunDotBorder),
            reason: 'a los $seconds s, puntos $a y $b',
          );
        }
      }
    }
  });

  test('se dibujan los tres a la vez', () {
    final recorder = PictureRecorder();

    marks.render(
      Canvas(recorder),
      slowed: true,
      burning: true,
      stunned: true,
      seconds: 0.5,
    );

    expect(recorder.endRecording(), isNotNull);
  });
}
