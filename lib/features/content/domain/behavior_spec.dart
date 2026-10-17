import 'package:meta/meta.dart';

/// Un comportamiento tal como aparece en los datos: su tipo (por ejemplo
/// "projectile" o "slow") y sus parámetros.
///
/// El contenido no conoce las clases que implementan cada tipo; las crea el
/// registro de comportamientos de la simulación a partir de [type].
@immutable
class BehaviorSpec {
  const new(this.type, [this.params = const {}]);

  final String type;
  final Map<String, Object?> params;

  @override
  String toString() => 'BehaviorSpec($type, $params)';
}
