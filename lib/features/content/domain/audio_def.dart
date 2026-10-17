import 'package:guardianes_chacra/core/services/audio_service.dart';
import 'package:meta/meta.dart';

/// Qué suena fuera de los niveles y para cada efecto
/// (`assets/content/audio.json`). Las rutas son relativas a
/// `assets/audio/`; la música de cada nivel está en su propio JSON.
@immutable
class AudioDef {
  const new({this.menuMusic, this.sfx = const {}});

  final String? menuMusic;

  /// Un efecto que falta aquí no suena.
  final Map<Sfx, String> sfx;
}
