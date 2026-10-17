import 'package:guardianes_chacra/core/services/audio_service.dart';

/// Anota lo que se pidió tocar, para comprobarlo en los tests.
class FakeAudioService implements AudioService {
  final List<String?> music = [];
  final List<Sfx> sfx = [];
  bool musicPaused = false;
  bool? musicOn;
  bool? effectsOn;
  Map<Sfx, String>? preloadedSfx;
  List<String>? preloadedMusic;

  @override
  Future<void> preload({
    required Map<Sfx, String> sfx,
    required Iterable<String> music,
  }) async {
    preloadedSfx = sfx;
    preloadedMusic = [...music];
  }

  @override
  void playMusic(String? file) => music.add(file);

  @override
  void pauseMusic() => musicPaused = true;

  @override
  void resumeMusic() => musicPaused = false;

  @override
  void playSfx(Sfx sfx) => this.sfx.add(sfx);

  @override
  bool get musicEnabled => musicOn ?? true;

  @override
  set musicEnabled(bool enabled) => musicOn = enabled;

  @override
  bool get effectsEnabled => effectsOn ?? true;

  @override
  set effectsEnabled(bool enabled) => effectsOn = enabled;
}
