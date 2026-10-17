import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:guardianes_chacra/core/services/audio_service.dart';

/// El audio real, con `flame_audio` (que usa `audioplayers`):
///
/// - la música va por `FlameAudio.bgm`, que además se pausa sola cuando la
///   app pasa a segundo plano y sigue al volver;
/// - cada efecto tiene un `AudioPool` con unas pocas voces, preparado de
///   antemano para que el primer disparo no se retrase.
///
/// Un archivo que falta o no se puede leer no es un error del juego: se
/// avisa una vez en la consola y ese sonido queda en silencio.
class FlameAudioService implements AudioService {
  static const _musicVolume = 0.5;
  static const _sfxVolume = 0.8;

  /// Voces por efecto: los disparos se superponen más que el resto.
  static int _voicesFor(Sfx sfx) =>
      sfx == Sfx.shot || sfx == Sfx.impact ? 4 : 2;

  final Map<Sfx, AudioPool> _pools = {};

  /// La pista pedida y la que suena de verdad (pueden diferir con la
  /// música apagada o en pausa).
  String? _track;
  String? _playing;
  var _paused = false;
  var _musicEnabled = true;
  var _effectsEnabled = true;

  /// Las órdenes a la música, en fila: `bgm.play` tarda (prepara el
  /// archivo) y una orden posterior no debe adelantarse.
  Future<void> _musicQueue = Future.value();

  @override
  Future<void> preload({
    required Map<Sfx, String> sfx,
    required Iterable<String> music,
  }) async {
    // Por la misma fila que las órdenes a la música: en Android, cambiar el
    // contexto de audio de un reproductor lo detiene, así que no debe llegar
    // después de que la música del menú empezó a sonar.
    _musicQueue = _musicQueue
        .then((_) => FlameAudio.bgm.initialize())
        .catchError((Object error) => _report('música', error));
    await _musicQueue;
    for (final MapEntry(key: effect, value: file) in sfx.entries) {
      try {
        _pools[effect] = await FlameAudio.createPool(
          file,
          maxPlayers: _voicesFor(effect),
        );
      } on Object catch (error) {
        _report(file, error);
      }
    }
    for (final file in music) {
      try {
        await FlameAudio.audioCache.load(file);
      } on Object catch (error) {
        _report(file, error);
      }
    }
  }

  @override
  void playMusic(String? file) {
    _track = file;
    _paused = false;
    _update();
  }

  @override
  void pauseMusic() {
    _paused = true;
    _update();
  }

  @override
  void resumeMusic() {
    _paused = false;
    _update();
  }

  @override
  bool get musicEnabled => _musicEnabled;

  @override
  set musicEnabled(bool enabled) {
    _musicEnabled = enabled;
    _update();
  }

  @override
  bool get effectsEnabled => _effectsEnabled;

  @override
  set effectsEnabled(bool enabled) => _effectsEnabled = enabled;

  @override
  void playSfx(Sfx sfx) {
    if (!_effectsEnabled) return;
    final pool = _pools[sfx];
    if (pool == null) return;
    unawaited(
      pool.start(volume: _sfxVolume).then<void>((_) {}, onError: _ignore),
    );
  }

  /// Lleva la música al estado pedido: qué pista, en pausa o apagada.
  void _update() {
    final track = _musicEnabled ? _track : null;
    final paused = _paused;
    _musicQueue = _musicQueue.then((_) async {
      try {
        if (track == null) {
          if (_playing != null) await FlameAudio.bgm.stop();
          _playing = null;
        } else if (track != _playing) {
          await FlameAudio.bgm.play(track, volume: _musicVolume);
          _playing = track;
          if (paused) await FlameAudio.bgm.pause();
        } else if (paused && FlameAudio.bgm.isPlaying) {
          await FlameAudio.bgm.pause();
        } else if (!paused && !FlameAudio.bgm.isPlaying) {
          await FlameAudio.bgm.resume();
        }
      } on Object catch (error) {
        _report(track ?? 'música', error);
        _playing = null;
      }
    });
  }

  final Set<String> _reported = {};

  void _report(String file, Object error) {
    if (_reported.add(file)) {
      debugPrint('Audio: no se pudo usar $file ($error)');
    }
  }

  static void _ignore(Object _) {}
}
