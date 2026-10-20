import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/audio.dart';
import 'package:guardianes_chacra/app/haptics.dart';
import 'package:guardianes_chacra/core/services/audio_service.dart';
import 'package:guardianes_chacra/core/services/haptics_service.dart';
import 'package:guardianes_chacra/features/settings/presentation/settings_providers.dart';

/// El sonido y la vibración de los controles de la interfaz (botones,
/// interruptores, pestañas). Respeta los interruptores de Ajustes: el de
/// Efectos lo aplica el audio y el de Vibración se lee aquí en cada toque.
class UiFeedback {
  const new(this._ref);

  final Ref _ref;

  /// Se tocó un control.
  void tap() => _play(Sfx.uiTap, Haptic.tap);

  /// Se tocó algo que no se puede hacer (no alcanza el maíz).
  void deny() => _play(Sfx.uiDeny, Haptic.deny);

  /// Se llenó una estrella de la victoria.
  void star() => _play(Sfx.star, Haptic.star);

  void _play(Sfx sfx, Haptic haptic) {
    _ref.read(audioServiceProvider).playSfx(sfx);
    if (_ref.read(settingsProvider).vibration) {
      _ref.read(hapticsServiceProvider).vibrate(haptic);
    }
  }
}

final uiFeedbackProvider = Provider<UiFeedback>(UiFeedback.new);
