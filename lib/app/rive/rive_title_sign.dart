import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/rive/rive_binding.dart';

/// Los nombres del artboard `TitleSign` (ver `docs/UI_RIVE.md`).
abstract final class TitleSignRive {
  static const artboard = 'TitleSign';
  static const viewModel = 'TitleSign';

  /// El texto del cartel (se achica solo si no entra).
  static const title = 'title';
}

/// El cartel de madera con hojas de los títulos. Sin el archivo de Rive, el
/// texto con el estilo de título del tema.
class RiveTitleSign extends ConsumerStatefulWidget {
  const new({required this.title, this.width = 288, super.key});

  final String title;

  /// Ancho a escala de letra 1 (el artboard mide 360 × 96).
  final double width;

  @override
  ConsumerState<RiveTitleSign> createState() => _RiveTitleSignState();
}

class _RiveTitleSignState extends ConsumerState<RiveTitleSign>
    with RiveBindingState<RiveTitleSign> {
  @override
  String get artboardName => TitleSignRive.artboard;

  @override
  void bind(RiveBinding binding) =>
      binding.string(TitleSignRive.title).value = widget.title;

  @override
  void didUpdateWidget(RiveTitleSign oldWidget) {
    super.didUpdateWidget(oldWidget);
    binding?.viewModel.string(TitleSignRive.title)?.value = widget.title;
  }

  @override
  Widget build(BuildContext context) {
    final binding = this.binding;
    final width = MediaQuery.textScalerOf(context).scale(widget.width);
    return Semantics(
      header: true,
      label: widget.title,
      excludeSemantics: true,
      child: binding == null
          ? Text(
              widget.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            )
          : SizedBox(
              width: width,
              height: width * 96 / 360,
              child: binding.widget(),
            ),
    );
  }
}
