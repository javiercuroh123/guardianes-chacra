import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/rive/rive_binding.dart';

/// Los nombres del artboard `Collca` (ver `docs/UI_RIVE.md`).
abstract final class CollcaRive {
  static const artboard = 'Collca';
  static const viewModel = 'Collca';
}

/// La collca vacía de la derrota: el silo de adobe con la puerta abierta y
/// un poco de polvo que sube. Es decoración: TalkBack no la lee. Sin el
/// archivo de Rive, un ícono.
class RiveCollca extends ConsumerStatefulWidget {
  const new({this.size = 110, super.key});

  /// Lado a escala de letra 1 (el artboard mide 120 × 120).
  final double size;

  @override
  ConsumerState<RiveCollca> createState() => _RiveCollcaState();
}

class _RiveCollcaState extends ConsumerState<RiveCollca>
    with RiveBindingState<RiveCollca> {
  @override
  String get artboardName => CollcaRive.artboard;

  @override
  void bind(RiveBinding binding) {}

  @override
  Widget build(BuildContext context) {
    final binding = this.binding;
    final size = MediaQuery.textScalerOf(context).scale(widget.size);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: binding != null
            ? binding.widget()
            : Icon(
                Icons.warehouse_outlined,
                size: size * 0.6,
                color: Theme.of(context).colorScheme.outline,
              ),
      ),
    );
  }
}
