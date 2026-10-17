import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/core/services/audio_service.dart';
import 'package:guardianes_chacra/features/content/presentation/content_providers.dart';
import 'package:guardianes_chacra/features/settings/presentation/settings_providers.dart';

/// El audio de la app. Por defecto, en silencio; `main.dart` pone el real
/// (`FlameAudioService`).
final audioServiceProvider = Provider<AudioService>(
  (ref) => SilentAudioService(),
);

/// Une el audio con el resto de la app:
///
/// - los interruptores de Música y Efectos de Ajustes lo encienden o apagan;
/// - cuando el contenido termina de cargar, prepara todos los sonidos y
///   empieza la música de los menús.
///
/// La música de cada nivel la pone la partida (ver `BattleFeedback`).
/// Vive en `app/` porque une audio, ajustes y contenido; `GuardianesApp`
/// lo mantiene vivo.
final audioDirectorProvider = Provider<void>((ref) {
  final audio = ref.watch(audioServiceProvider);

  ref
    ..listen(settingsProvider, (_, settings) {
      audio
        ..musicEnabled = settings.music
        ..effectsEnabled = settings.effects;
    }, fireImmediately: true)
    ..listen(gameContentProvider, (_, content) {
      if (content case AsyncData(:final value)) {
        final menu = value.audio.menuMusic;
        unawaited(
          audio.preload(
            sfx: value.audio.sfx,
            music: {?menu, for (final level in value.levels) ?level.music},
          ),
        );
        audio.playMusic(menu);
      }
    }, fireImmediately: true);
});
