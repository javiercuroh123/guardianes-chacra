import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/rive/rive_binding.dart';

/// Los nombres del artboard `SceneSign` (ver `docs/UI_RIVE.md`).
abstract final class SceneSignRive {
  static const artboard = 'SceneSign';
  static const viewModel = 'SceneSign';
  static const enumName = 'SceneVariant';

  /// El texto del cartel (se achica y pasa a dos líneas si no entra).
  static const title = 'title';

  /// Qué adorno lleva: un valor de [SceneSignVariant].
  static const variant = 'variant';
}

/// Los adornos del cartel de las escenas.
enum SceneSignVariant {
  /// El sol con espiral, que gira despacio.
  pause,

  /// El sol que sonríe.
  victory,

  /// Sin sol y con la madera más apagada.
  defeat,
}

/// El cartel de madera de la pausa, la victoria y la derrota: cae al
/// aparecer, con mazorcas a los lados y el adorno de [variant] arriba.
/// Sin el archivo de Rive, el título con el estilo del tema.
class RiveSceneSign extends ConsumerStatefulWidget {
  const new({
    required this.title,
    required this.variant,
    this.width = 300,
    super.key,
  });

  final String title;
  final SceneSignVariant variant;

  /// Ancho a escala de letra 1 (el artboard mide 380 × 150).
  final double width;

  /// Alto del artboard respecto de su ancho.
  static const double aspect = 150 / 380;

  /// Dónde queda el borde de arriba del panel, respecto del alto del
  /// cartel: la tabla se apoya sobre él.
  static const double panelTop = 0.7;

  @override
  ConsumerState<RiveSceneSign> createState() => _RiveSceneSignState();
}

class _RiveSceneSignState extends ConsumerState<RiveSceneSign>
    with RiveBindingState<RiveSceneSign> {
  @override
  String get artboardName => SceneSignRive.artboard;

  @override
  void bind(RiveBinding binding) => _apply(binding);

  void _apply(RiveBinding binding) {
    binding.string(SceneSignRive.title).value = widget.title;
    binding.enumerator(SceneSignRive.variant).value = widget.variant.name;
  }

  @override
  void didUpdateWidget(RiveSceneSign oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (binding case final binding?) _apply(binding);
  }

  @override
  Widget build(BuildContext context) {
    final binding = this.binding;
    final width = MediaQuery.textScalerOf(context).scale(widget.width);
    return Semantics(
      header: true,
      label: widget.title,
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        height: width * RiveSceneSign.aspect,
        child: binding != null
            ? binding.widget()
            : Align(
                alignment: const Alignment(0, 0.45),
                child: Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
      ),
    );
  }
}
