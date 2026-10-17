import 'package:guardianes_chacra/features/battle/domain/behaviors/abilities/pest_ability.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/attacks/guardian_behavior.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/effects/status_effect.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/targeting/targeting_strategies.dart';
import 'package:guardianes_chacra/features/battle/domain/registry/behavior_params.dart';
import 'package:guardianes_chacra/features/battle/domain/registry/core_behaviors.dart';
import 'package:guardianes_chacra/features/content/domain/behavior_spec.dart';

typedef GuardianBehaviorFactory =
    GuardianBehavior Function(BehaviorParams params);
typedef EffectFactory = StatusEffect Function(BehaviorParams params);
typedef AbilityFactory = PestAbility Function(BehaviorParams params);

/// Error en los datos de un comportamiento: tipo desconocido o parámetro
/// que falta o no es válido.
class BehaviorDataError implements Exception {
  new(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Traduce el `type` de los datos (por ejemplo "slow" o "split_on_death")
/// a la clase que lo implementa.
///
/// Es la pieza que permite la composición: un guardián o una plaga se
/// arman combinando tipos registrados, y un tipo nuevo se agrega
/// registrando una clase nueva, sin modificar el motor ni las existentes.
class BehaviorRegistry {
  new();

  /// Un registro con los comportamientos de serie (`core_behaviors.dart`).
  factory withDefaults() => registerCoreBehaviors(BehaviorRegistry());

  final _targeting = <String, TargetingStrategy>{};
  final _guardianBehaviors = <String, GuardianBehaviorFactory>{};
  final _effects = <String, EffectFactory>{};
  final _abilities = <String, AbilityFactory>{};

  void registerTargeting(String id, TargetingStrategy strategy) =>
      _register(_targeting, id, strategy);

  void registerGuardianBehavior(String type, GuardianBehaviorFactory create) =>
      _register(_guardianBehaviors, type, create);

  void registerEffect(String type, EffectFactory create) =>
      _register(_effects, type, create);

  void registerAbility(String type, AbilityFactory create) =>
      _register(_abilities, type, create);

  bool hasTargeting(String id) => _targeting.containsKey(id);

  TargetingStrategy targeting(String id) =>
      _targeting[id] ??
      (throw _unknown('Estrategia de apuntado desconocida', id, _targeting));

  GuardianBehavior createGuardianBehavior(BehaviorSpec spec) => _create(
    _guardianBehaviors,
    spec,
    'Tipo de comportamiento de guardián desconocido',
  );

  StatusEffect createEffect(BehaviorSpec spec) =>
      _create(_effects, spec, 'Tipo de efecto desconocido');

  PestAbility createAbility(BehaviorSpec spec) =>
      _create(_abilities, spec, 'Tipo de habilidad de plaga desconocido');

  T _create<T>(
    Map<String, T Function(BehaviorParams params)> factories,
    BehaviorSpec spec,
    String unknownLabel,
  ) {
    final create = factories[spec.type];
    if (create == null) throw _unknown(unknownLabel, spec.type, factories);
    return create(BehaviorParams(spec.type, spec.params, this));
  }

  static void _register<T>(Map<String, T> into, String type, T value) {
    if (into.containsKey(type)) {
      throw StateError('El tipo "$type" ya está registrado.');
    }
    into[type] = value;
  }

  static BehaviorDataError _unknown(
    String label,
    String type,
    Map<String, Object?> registered,
  ) {
    final available = registered.keys.toList()..sort();
    return BehaviorDataError(
      '$label: "$type". Disponibles: ${available.join(', ')}.',
    );
  }
}
