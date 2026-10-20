/// Las vibraciones del juego. [tap] y [deny] son de los controles de la
/// interfaz (tocar un botón y "no se puede").
enum Haptic { collcaDamaged, boss, tap, deny }

/// La vibración del teléfono, detrás de una interfaz (como el audio): el
/// resto del código pide "la vibración del jefe" y no sabe cómo se hace.
/// La app usa `SystemHapticsService`; los tests y cualquier arranque sin
/// vibración, [SilentHapticsService].
abstract interface class HapticsService {
  void vibrate(Haptic haptic);
}

/// No vibra. Es la implementación por defecto.
class SilentHapticsService implements HapticsService {
  @override
  void vibrate(Haptic haptic) {}
}
