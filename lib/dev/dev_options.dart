import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Las herramientas de desarrollo (overlay, panel, trucos) existen en los
/// modos debug y profile: en profile es donde se mide el rendimiento de
/// verdad (ver `docs/RENDIMIENTO.md`), y ahí hace falta el botón de
/// estrés. En una compilación de lanzamiento (release) esta constante vale
/// `false` y el compilador quita el código que depende de ella.
const bool devToolsEnabled = !kReleaseMode;

/// Qué muestra la prueba de Rive del panel de desarrollo (ver
/// `lib/dev/rive_bench.dart` y `docs/UI_RIVE.md`).
enum RiveBenchMode {
  off(count: 0, animated: 0),

  /// El peor caso: muchos widgets animándose sin parar.
  all(count: 12, animated: 12),

  /// Parecido al HUD de la Fase 4: seis controles y solo dos cambiando
  /// (el maíz y las papas).
  hud(count: 6, animated: 2);

  new({required this.count, required this.animated});

  final int count;
  final int animated;
}

/// Opciones de desarrollo que duran mientras la app está abierta (no se
/// guardan): no son del jugador.
@immutable
class DevOptions {
  const new({
    this.unlockAll = false,
    this.debugOverlay = false,
    this.riveBench = RiveBenchMode.off,
    this.riveSharedTexture = false,
  });

  /// Todos los niveles y guardianes abiertos (para "elegir nivel").
  final bool unlockAll;

  /// Dibuja caminos, alcances, FPS y conteos sobre la partida.
  final bool debugOverlay;

  /// Contadores de Rive animándose sobre la partida, para medir cuánto
  /// cuestan los widgets de Rive.
  final RiveBenchMode riveBench;

  /// Los contadores de la prueba dibujan en una sola textura (`RivePanel`).
  final bool riveSharedTexture;

  DevOptions copyWith({
    bool? unlockAll,
    bool? debugOverlay,
    RiveBenchMode? riveBench,
    bool? riveSharedTexture,
  }) => DevOptions(
    unlockAll: unlockAll ?? this.unlockAll,
    debugOverlay: debugOverlay ?? this.debugOverlay,
    riveBench: riveBench ?? this.riveBench,
    riveSharedTexture: riveSharedTexture ?? this.riveSharedTexture,
  );
}

class DevOptionsController extends Notifier<DevOptions> {
  @override
  DevOptions build() => const DevOptions();

  set unlockAll(bool on) => state = state.copyWith(unlockAll: on);
  bool get unlockAll => state.unlockAll;

  set debugOverlay(bool on) => state = state.copyWith(debugOverlay: on);
  bool get debugOverlay => state.debugOverlay;

  set riveBench(RiveBenchMode mode) => state = state.copyWith(riveBench: mode);
  RiveBenchMode get riveBench => state.riveBench;

  set riveSharedTexture(bool on) =>
      state = state.copyWith(riveSharedTexture: on);
  bool get riveSharedTexture => state.riveSharedTexture;
}

final devOptionsProvider = NotifierProvider<DevOptionsController, DevOptions>(
  DevOptionsController.new,
);
