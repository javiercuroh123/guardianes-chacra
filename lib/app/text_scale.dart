import 'package:flutter/widgets.dart';

/// Hasta cuánto crece el texto con la letra grande del teléfono
/// (Ajustes de Android → Pantalla → Tamaño de fuente).
abstract final class TextScaleLimits {
  /// Los menús: hasta el doble, lo máximo que permite Android.
  static const double menus = 2;

  /// La partida (HUD y menús radiales): crece un poco, pero no tanto como
  /// para tapar el mapa.
  static const double battle = 1.3;
}

/// Limita la letra de toda la app a [TextScaleLimits.menus]. Va en el
/// `builder` de `MaterialApp`, que envuelve todas las pantallas.
Widget clampAppTextScale(BuildContext context, Widget? child) =>
    MediaQuery.withClampedTextScaling(
      maxScaleFactor: TextScaleLimits.menus,
      child: child ?? const SizedBox.shrink(),
    );
