/// Trucos de desarrollo para probar niveles sin tener que jugarlos bien.
///
/// La simulación los consulta en solo dos lugares (gastar maíz y perder
/// papas), así las reglas normales no cambian. Solo los enciende el panel
/// de desarrollo (nunca en release; ver `lib/dev/`); por defecto, todos
/// apagados.
class SimulationCheats {
  /// Construir y mejorar no gasta maíz, y siempre alcanza.
  bool infiniteCorn = false;

  /// Las plagas que llegan a la collca no se comen papas.
  bool invincible = false;
}
