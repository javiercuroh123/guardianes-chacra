import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/fixed_step_clock.dart';

void main() {
  const frame = 1 / 60;

  int stepsDuring(FixedStepClock clock, {required int frames}) {
    var steps = 0;
    for (var i = 0; i < frames; i++) {
      steps += clock.advance(frame);
    }
    return steps;
  }

  test('a velocidad x1 da 30 pasos por segundo', () {
    final clock = FixedStepClock();

    expect(stepsDuring(clock, frames: 60), 30);
  });

  test('a velocidad x2 da 60 pasos por segundo', () {
    final clock = FixedStepClock()..speed = GameSpeed.fast;

    expect(stepsDuring(clock, frames: 60), 60);
  });

  test('en pausa no da pasos ni acumula tiempo', () {
    final clock = FixedStepClock()..paused = true;

    expect(clock.advance(5), 0);

    clock.paused = false;
    expect(clock.advance(1 / 30), 1);
  });

  test('un frame muy largo da como máximo maxStepsPerUpdate pasos', () {
    final clock = FixedStepClock(maxStepsPerUpdate: 4);

    // La app estuvo 2 s congelada: no intenta ponerse al día de golpe.
    expect(clock.advance(2), 4);
    // Y descarta el atraso en lugar de arrastrarlo a los frames siguientes.
    expect(clock.advance(1 / 30), 1);
  });

  test('alpha indica cuánto se avanzó hacia el siguiente paso', () {
    final clock = FixedStepClock();

    expect(clock.advance(frame), 0);
    expect(clock.alpha, closeTo(0.5, 1e-9));

    expect(clock.advance(frame), 1);
    expect(clock.alpha, closeTo(0, 1e-9));
  });
}
