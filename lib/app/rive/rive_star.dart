import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/app_theme.dart';
import 'package:guardianes_chacra/app/rive/rive_binding.dart';

/// Los nombres del artboard `Star` (ver `docs/UI_RIVE.md`).
abstract final class StarRive {
  static const artboard = 'Star';
  static const viewModel = 'Star';

  /// Al pasar a `true` la estrella se llena con un estallido (o de golpe,
  /// si se pidió menos movimiento); al volver a `false` se encoge.
  static const filled = 'filled';
}

/// Una estrella de la puntuación. El sonido que acompaña a cada estrella lo
/// toca quien cambia [filled] (la victoria, en la Fase 5).
class RiveStar extends ConsumerStatefulWidget {
  const new({required this.filled, this.size = 44, super.key});

  final bool filled;
  final double size;

  @override
  ConsumerState<RiveStar> createState() => _RiveStarState();
}

class _RiveStarState extends ConsumerState<RiveStar>
    with RiveBindingState<RiveStar> {
  @override
  String get artboardName => StarRive.artboard;

  @override
  void bind(RiveBinding binding) =>
      binding.boolean(StarRive.filled).value = widget.filled;

  @override
  void didUpdateWidget(RiveStar oldWidget) {
    super.didUpdateWidget(oldWidget);
    binding?.viewModel.boolean(StarRive.filled)?.value = widget.filled;
  }

  @override
  Widget build(BuildContext context) {
    final binding = this.binding;
    if (binding == null) {
      final colors = GameColors.of(context);
      return Icon(
        widget.filled ? Icons.star_rounded : Icons.star_outline_rounded,
        size: widget.size,
        color: widget.filled ? colors.star : colors.starEmpty,
      );
    }
    return SizedBox.square(dimension: widget.size, child: binding.widget());
  }
}
