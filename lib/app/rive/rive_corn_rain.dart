import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/rive/rive_binding.dart';
import 'package:rive/rive.dart' as rive;

/// Los nombres del artboard `CornRain` (ver `docs/UI_RIVE.md`).
abstract final class CornRainRive {
  static const artboard = 'CornRain';
  static const viewModel = 'CornRain';

  /// Caen granos de maíz durante unos 3 s y se detiene (con menos
  /// movimiento no cae nada).
  static const rain = 'rain';
}

/// Granos de maíz que caen sobre la victoria. Llena a su padre, no recibe
/// toques y TalkBack no la lee. Llueve cada vez que sube [showers].
/// Sin el archivo de Rive no dibuja nada: es solo un adorno.
class RiveCornRain extends ConsumerStatefulWidget {
  const new({required this.showers, super.key});

  /// Cada vez que sube, llueve (con 0 no llueve).
  final int showers;

  /// Lo que dura la lluvia (`Rain`, 168 cuadros a 60).
  static const duration = Duration(milliseconds: 2800);

  @override
  ConsumerState<RiveCornRain> createState() => _RiveCornRainState();
}

class _RiveCornRainState extends ConsumerState<RiveCornRain>
    with RiveBindingState<RiveCornRain> {
  @override
  String get artboardName => CornRainRive.artboard;

  @override
  void bind(RiveBinding binding) {
    final rain = binding.trigger(CornRainRive.rain);
    if (widget.showers > 0) rain.trigger();
  }

  @override
  void didUpdateWidget(RiveCornRain oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showers > oldWidget.showers) {
      binding?.viewModel.trigger(CornRainRive.rain)?.trigger();
    }
  }

  @override
  Widget build(BuildContext context) {
    final binding = this.binding;
    if (binding == null) return const SizedBox.shrink();
    return IgnorePointer(
      // A lo ancho y desde arriba: los granos empiezan sobre el borde de
      // arriba aunque el padre sea más alto que el artboard.
      child: ExcludeSemantics(
        child: binding.widget(
          fit: rive.Fit.fitWidth,
          alignment: Alignment.topCenter,
        ),
      ),
    );
  }
}
