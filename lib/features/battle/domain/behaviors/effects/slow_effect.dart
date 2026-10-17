import 'dart:math' as math;

import 'package:guardianes_chacra/features/battle/domain/behaviors/effects/status_effect.dart';
import 'package:guardianes_chacra/features/battle/domain/registry/behavior_params.dart';

/// Reduce la velocidad de la plaga a [factor] (0,6 = 60 % de su velocidad).
///
/// Acumulación: no se suman. Gana la más fuerte; si la nueva es igual de
/// fuerte, queda la duración más larga; una más débil se ignora.
///
/// Datos: `factor` (entre 0 y 1) y `duration` (s).
final class SlowEffect extends StatusEffect {
  const new({required this.factor, required this.durationTicks});

  factory fromParams(BehaviorParams params) => SlowEffect(
    factor: params.number('factor', min: 0, max: 1),
    durationTicks: params.ticks('duration'),
  );

  final double factor;

  @override
  final int durationTicks;

  @override
  String get type => 'slow';

  @override
  double get speedFactor => factor;

  @override
  ActiveEffect mergeInto(ActiveEffect current) {
    final currentFactor = (current.effect as SlowEffect).factor;
    if (factor < currentFactor) return ActiveEffect(this, durationTicks);
    if (factor == currentFactor) {
      current.remaining = math.max(current.remaining, durationTicks);
    }
    return current;
  }
}
