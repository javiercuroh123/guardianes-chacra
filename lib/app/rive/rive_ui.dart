import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart' as rive;

/// La interfaz hecha en Rive: un solo archivo con todos los artboards. Qué
/// busca el código en él (artboards, view models y propiedades) está en
/// `docs/UI_RIVE.md` y lo revisa `rive_contract_test.dart`.
abstract final class RiveUi {
  static const asset = 'assets/rive/guardianes_ui.riv';

  /// La state machine de cada artboard.
  static const stateMachine = 'Main';

  /// Con qué se dibuja: el renderer de Flutter (por defecto) o el de Rive
  /// (`--dart-define=RIVE_RENDERER=rive`). Con `none` no se carga Rive y
  /// cada pantalla usa el respaldo: sirve de línea base al medir.
  ///
  /// En la Fase 1 de la interfaz, en el Redmi con 150 plagas a x2, seis
  /// widgets como los del HUD dieron 114 FPS con el de Flutter y 59 con el
  /// de Rive (75 con `RivePanel`): ver `docs/UI_RIVE.md`. El de Flutter no
  /// tiene *vector feathering*: los brillos y sombras suaves se hacen con
  /// degradados.
  static rive.Factory? get renderer => switch (_rendererName) {
    'none' => null,
    'rive' => rive.Factory.rive,
    _ => rive.Factory.flutter,
  };

  static const _rendererName = String.fromEnvironment('RIVE_RENDERER');

  /// Cuánto se espera a que Rive se inicie (en Android es inmediato).
  static const _initTimeout = Duration(seconds: 10);

  /// Carga el archivo, o `null` si no se puede (faltan las librerías
  /// nativas, el archivo está roto): entonces cada pantalla usa su aspecto
  /// de Flutter.
  static Future<rive.File?> load() async {
    if (_rendererName == 'none') return null;
    try {
      // En la web, Rive baja su módulo de WebAssembly (de jsDelivr) al
      // iniciarse: hasta entonces no se puede tocar nada de Rive, tampoco
      // `Factory.flutter` (la versión web se quedaba en blanco). Si no
      // llega (sin internet, la espera no termina nunca), el respaldo.
      final ready = await rive.RiveNative.init().timeout(
        _initTimeout,
        onTimeout: () => false,
      );
      if (!ready) return null;
      return await rive.File.asset(asset, riveFactory: renderer!);
    } on Object catch (error) {
      debugPrint('Rive: no se pudo cargar $asset ($error); uso el respaldo.');
      return null;
    }
  }
}

/// El archivo de Rive ya cargado. Por defecto `null` (los tests no cargan
/// las librerías nativas y ven el aspecto de Flutter); `main.dart` pone el
/// real.
final riveFileProvider = Provider<rive.File?>((ref) => null);
