import 'package:meta/meta.dart';

/// Idioma elegido en Ajustes; `system` sigue al del teléfono.
enum AppLanguage { system, es, en }

/// Los ajustes del jugador. La música, los efectos y la vibración se
/// guardan desde ya, aunque el sonido llega en la Fase 8.
@immutable
class Settings {
  const new({
    this.music = true,
    this.effects = true,
    this.vibration = true,
    this.damageNumbers = false,
    this.language = AppLanguage.system,
  });

  final bool music;
  final bool effects;
  final bool vibration;

  /// Muestra el daño que recibe cada plaga (apagado por defecto: la
  /// pantalla queda más limpia).
  final bool damageNumbers;
  final AppLanguage language;

  Settings copyWith({
    bool? music,
    bool? effects,
    bool? vibration,
    bool? damageNumbers,
    AppLanguage? language,
  }) => Settings(
    music: music ?? this.music,
    effects: effects ?? this.effects,
    vibration: vibration ?? this.vibration,
    damageNumbers: damageNumbers ?? this.damageNumbers,
    language: language ?? this.language,
  );

  @override
  bool operator ==(Object other) =>
      other is Settings &&
      other.music == music &&
      other.effects == effects &&
      other.vibration == vibration &&
      other.damageNumbers == damageNumbers &&
      other.language == language;

  @override
  int get hashCode =>
      Object.hash(music, effects, vibration, damageNumbers, language);
}
