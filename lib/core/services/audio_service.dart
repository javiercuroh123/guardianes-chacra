/// Los efectos de sonido del juego. Qué archivo suena para cada uno lo dice
/// `assets/content/audio.json` (ver `docs/CONTENIDO.md`).
enum Sfx { shot, impact, pestDefeated, collcaDamaged, victory, defeat, boss }

/// El sonido del juego, detrás de una interfaz: el resto del código no sabe
/// qué paquete lo reproduce. La app usa `FlameAudioService`; los tests y
/// cualquier arranque sin audio, [SilentAudioService].
abstract interface class AudioService {
  /// Prepara los archivos para que el primer sonido no se retrase. Un
  /// archivo que falta no es un error: ese sonido queda en silencio.
  Future<void> preload({
    required Map<Sfx, String> sfx,
    required Iterable<String> music,
  });

  /// Toca [file] en bucle (o nada, si es `null`). Si ya está sonando, sigue
  /// sin empezar de nuevo.
  void playMusic(String? file);

  void pauseMusic();

  void resumeMusic();

  void playSfx(Sfx sfx);

  /// Con la música apagada, [playMusic] recuerda la pista y la toca al
  /// volver a encenderla.
  bool get musicEnabled;
  set musicEnabled(bool enabled);

  bool get effectsEnabled;
  set effectsEnabled(bool enabled);
}

/// No suena nada. Es la implementación por defecto.
class SilentAudioService implements AudioService {
  @override
  Future<void> preload({
    required Map<Sfx, String> sfx,
    required Iterable<String> music,
  }) async {}

  @override
  void playMusic(String? file) {}

  @override
  void pauseMusic() {}

  @override
  void resumeMusic() {}

  @override
  void playSfx(Sfx sfx) {}

  @override
  bool musicEnabled = true;

  @override
  bool effectsEnabled = true;
}
