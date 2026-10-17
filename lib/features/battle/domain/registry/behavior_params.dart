import 'package:guardianes_chacra/features/battle/domain/behaviors/effects/status_effect.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/sim_time.dart';
import 'package:guardianes_chacra/features/battle/domain/registry/behavior_registry.dart';
import 'package:guardianes_chacra/features/content/domain/behavior_spec.dart';
import 'package:guardianes_chacra/features/content/domain/pest_def.dart';

/// Lee los parámetros de un comportamiento con errores claros que nombran
/// el tipo y el parámetro (por ejemplo, `slow: falta "factor"`).
///
/// Cada comportamiento lee aquí lo que necesita en su `fromParams`; así un
/// error en los datos aparece al cargar el nivel, no a mitad de partida.
class BehaviorParams {
  new(this.type, this._values, this._registry);

  final String type;
  final Map<String, Object?> _values;
  final BehaviorRegistry _registry;

  double number(String key, {double? min, double? max}) {
    final value = _required(key);
    if (value is! num) throw error('"$key" debe ser un número');
    return _inRange(key, value.toDouble(), min, max);
  }

  double numberOr(String key, double fallback, {double? min, double? max}) =>
      _values[key] == null ? fallback : number(key, min: min, max: max);

  double positive(String key) {
    final value = number(key);
    if (value <= 0) throw error('"$key" debe ser mayor que 0');
    return value;
  }

  int integer(String key, {int? min}) {
    final value = _required(key);
    if (value is! int) throw error('"$key" debe ser un entero');
    if (min != null && value < min) {
      throw error('"$key" debe ser al menos $min');
    }
    return value;
  }

  String string(String key) {
    final value = _required(key);
    if (value is! String) throw error('"$key" debe ser un texto');
    return value;
  }

  /// Segundos en los datos, convertidos a ticks.
  int ticks(String key) => secondsToTicks(number(key, min: 0));

  DamageType damageType(String key) {
    final name = string(key);
    for (final type in DamageType.values) {
      if (type.name == name) return type;
    }
    throw error('"$key" debe ser uno de: ${_names(DamageType.values)}');
  }

  /// Multiplicadores por etiqueta, por ejemplo `{"flying": 2}`. Opcional.
  Map<PestTag, double> tagMultipliers(String key) {
    final value = _values[key];
    if (value == null) return const {};
    if (value is! Map) throw error('"$key" debe ser un objeto');

    final result = <PestTag, double>{};
    for (final MapEntry(key: tagName, value: multiplier) in value.entries) {
      final tag = PestTag.values.where((tag) => tag.name == tagName);
      if (tag.isEmpty) {
        throw error(
          '"$key" tiene una etiqueta desconocida "$tagName" '
          '(válidas: ${_names(PestTag.values)})',
        );
      }
      if (multiplier is! num) throw error('"$key" debe tener números');
      result[tag.single] = multiplier.toDouble();
    }
    return result;
  }

  /// Lista de efectos, cada uno con su `type` y sus parámetros. Opcional.
  List<StatusEffect> effects(String key) {
    final value = _values[key];
    if (value == null) return const [];
    if (value is! List) throw error('"$key" debe ser una lista');
    return [for (final item in value) _effect(key, item)];
  }

  BehaviorDataError error(String detail) => BehaviorDataError('$type: $detail');

  StatusEffect _effect(String key, Object? item) {
    if (item is! Map || item['type'] is! String) {
      throw error('cada elemento de "$key" necesita "type"');
    }
    final params = <String, Object?>{
      for (final MapEntry(:key, :value) in item.entries)
        if (key != 'type') key as String: value,
    };
    try {
      return _registry.createEffect(
        BehaviorSpec(item['type'] as String, params),
      );
    } on BehaviorDataError catch (nested) {
      throw error('"$key": ${nested.message}');
    }
  }

  Object _required(String key) {
    final value = _values[key];
    if (value == null) throw error('falta "$key"');
    return value;
  }

  double _inRange(String key, double value, double? min, double? max) {
    if (min != null && max != null && (value < min || value > max)) {
      throw error('"$key" debe estar entre ${_format(min)} y ${_format(max)}');
    }
    if (min != null && value < min) {
      throw error('"$key" debe ser al menos ${_format(min)}');
    }
    if (max != null && value > max) {
      throw error('"$key" debe ser como máximo ${_format(max)}');
    }
    return value;
  }

  static String _names(List<Enum> values) =>
      values.map((value) => value.name).join(', ');

  static String _format(double value) => value == value.truncateToDouble()
      ? value.toInt().toString()
      : value.toString();
}
