import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Las herramientas de desarrollo (overlay, panel, trucos) existen en los
/// modos debug y profile: en profile es donde se mide el rendimiento de
/// verdad (ver `docs/RENDIMIENTO.md`), y ahí hace falta el botón de
/// estrés. En una compilación de lanzamiento (release) esta constante vale
/// `false` y el compilador quita el código que depende de ella.
const bool devToolsEnabled = !kReleaseMode;

/// Opciones de desarrollo que duran mientras la app está abierta (no se
/// guardan): no son del jugador.
@immutable
class DevOptions {
  const new({this.unlockAll = false, this.debugOverlay = false});

  /// Todos los niveles y guardianes abiertos (para "elegir nivel").
  final bool unlockAll;

  /// Dibuja caminos, alcances, FPS y conteos sobre la partida.
  final bool debugOverlay;

  DevOptions copyWith({bool? unlockAll, bool? debugOverlay}) => DevOptions(
    unlockAll: unlockAll ?? this.unlockAll,
    debugOverlay: debugOverlay ?? this.debugOverlay,
  );
}

class DevOptionsController extends Notifier<DevOptions> {
  @override
  DevOptions build() => const DevOptions();

  set unlockAll(bool on) => state = state.copyWith(unlockAll: on);
  bool get unlockAll => state.unlockAll;

  set debugOverlay(bool on) => state = state.copyWith(debugOverlay: on);
  bool get debugOverlay => state.debugOverlay;
}

final devOptionsProvider = NotifierProvider<DevOptionsController, DevOptions>(
  DevOptionsController.new,
);
