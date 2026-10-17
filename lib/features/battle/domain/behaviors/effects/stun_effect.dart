import 'dart:math' as math;

import 'package:guardianes_chacra/features/battle/domain/behaviors/effects/status_effect.dart';
import 'package:guardianes_chacra/features/battle/domain/registry/behavior_params.dart';

/// Detiene a la plaga mientras dura.
///
/// Acumulación: no se suma; queda la duración más larga.
///
/// Datos: `duration` (s).
final class StunEffect extends StatusEffect {
  const new({required this.durationTicks});

  factory fromParams(BehaviorParams params) =>
      StunEffect(durationTicks: params.ticks('duration'));

  @override
  final int durationTicks;

  @override
  String get type => 'stun';

  @override
  double get speedFactor => 0;

  @override
  ActiveEffect mergeInto(ActiveEffect current) =>
      current..remaining = math.max(current.remaining, durationTicks);
}
