import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/rive/rive_binding.dart';

/// Los nombres del artboard `Llama` (ver `docs/UI_RIVE.md`).
abstract final class LlamaRive {
  static const artboard = 'Llama';
  static const viewModel = 'Llama';
  static const enumName = 'LlamaMood';

  /// La cara: un valor de [LlamaMood].
  static const mood = 'mood';

  /// Un saltito de festejo.
  static const celebrate = 'celebrate';
}

enum LlamaMood {
  /// Sonríe, con la lengua afuera.
  happy,

  /// Cabeza gacha, orejas caídas y ceño.
  sad,
}

/// La llama de la chacra, de cuerpo entero: respira y parpadea, y salta
/// cada vez que sube [celebrations]. Es decoración: TalkBack no la lee.
/// Sin el archivo de Rive, un emoji de llama.
class RiveLlama extends ConsumerStatefulWidget {
  const new({
    required this.mood,
    this.celebrations = 0,
    this.height = 150,
    super.key,
  });

  final LlamaMood mood;

  /// Cada vez que sube, la llama salta (con 0 no salta).
  final int celebrations;

  /// Alto a escala de letra 1 (el artboard mide 240 × 270).
  final double height;

  static const double aspect = 240 / 270;

  @override
  ConsumerState<RiveLlama> createState() => _RiveLlamaState();
}

class _RiveLlamaState extends ConsumerState<RiveLlama>
    with RiveBindingState<RiveLlama> {
  @override
  String get artboardName => LlamaRive.artboard;

  @override
  void bind(RiveBinding binding) {
    binding.trigger(LlamaRive.celebrate);
    binding.enumerator(LlamaRive.mood).value = widget.mood.name;
    if (widget.celebrations > 0) {
      binding.trigger(LlamaRive.celebrate).trigger();
    }
  }

  @override
  void didUpdateWidget(RiveLlama oldWidget) {
    super.didUpdateWidget(oldWidget);
    final binding = this.binding;
    if (binding == null) return;
    binding.viewModel.enumerator(LlamaRive.mood)?.value = widget.mood.name;
    if (widget.celebrations > oldWidget.celebrations) {
      binding.viewModel.trigger(LlamaRive.celebrate)?.trigger();
    }
  }

  @override
  Widget build(BuildContext context) {
    final binding = this.binding;
    final height = MediaQuery.textScalerOf(context).scale(widget.height);
    return ExcludeSemantics(
      child: SizedBox(
        width: height * RiveLlama.aspect,
        height: height,
        child: binding != null
            ? binding.widget()
            : FittedBox(
                child: Text(
                  widget.mood == LlamaMood.happy ? '🦙' : '🦙💧',
                  style: const TextStyle(fontSize: 64),
                ),
              ),
      ),
    );
  }
}
