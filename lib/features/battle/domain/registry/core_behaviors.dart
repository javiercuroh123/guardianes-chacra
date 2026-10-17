import 'package:guardianes_chacra/features/battle/domain/behaviors/abilities/split_on_death.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/abilities/summon.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/attacks/area_attack.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/attacks/projectile_attack.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/attacks/support_aura.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/effects/burn_effect.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/effects/slow_effect.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/effects/stun_effect.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/targeting/targeting_strategies.dart';
import 'package:guardianes_chacra/features/battle/domain/registry/behavior_registry.dart';

/// Registra los comportamientos de serie. Es el único lugar que conoce
/// todas las clases: un comportamiento nuevo se agrega con una línea aquí
/// (o en otro registro), sin tocar el motor ni las clases existentes.
BehaviorRegistry registerCoreBehaviors(BehaviorRegistry registry) => registry
  ..registerTargeting('first', const FirstTargeting())
  ..registerTargeting('last', const LastTargeting())
  ..registerTargeting('strongest', const StrongestTargeting())
  ..registerTargeting('closest', const ClosestTargeting())
  ..registerGuardianBehavior('projectile', ProjectileAttack.fromParams)
  ..registerGuardianBehavior('area', AreaAttack.fromParams)
  ..registerGuardianBehavior('support_aura', SupportAura.fromParams)
  ..registerEffect('slow', SlowEffect.fromParams)
  ..registerEffect('burn', BurnEffect.fromParams)
  ..registerEffect('stun', StunEffect.fromParams)
  ..registerAbility('split_on_death', SplitOnDeath.fromParams)
  ..registerAbility('summon', Summon.fromParams);
