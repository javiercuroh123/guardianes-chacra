import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/rive/rive_binding.dart';

/// Los nombres del artboard `Badge` (ver `docs/UI_RIVE.md`).
abstract final class BadgeRive {
  static const artboard = 'Badge';
  static const viewModel = 'Badge';

  /// "¡Nuevo!", ya traducido. Cada ~3 s la etiqueta se menea (quieta si se
  /// pidió menos movimiento).
  static const label = 'label';
}

/// La etiqueta "¡Nuevo!" (plagas o guardianes que el jugador no vio).
class RiveBadge extends ConsumerStatefulWidget {
  const new({required this.label, super.key});

  final String label;

  static const Size size = Size(84, 32);

  @override
  ConsumerState<RiveBadge> createState() => _RiveBadgeState();
}

class _RiveBadgeState extends ConsumerState<RiveBadge>
    with RiveBindingState<RiveBadge> {
  @override
  String get artboardName => BadgeRive.artboard;

  @override
  void bind(RiveBinding binding) =>
      binding.string(BadgeRive.label).value = widget.label;

  @override
  void didUpdateWidget(RiveBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    binding?.viewModel.string(BadgeRive.label)?.value = widget.label;
  }

  @override
  Widget build(BuildContext context) {
    final binding = this.binding;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return Semantics(
      label: widget.label,
      excludeSemantics: true,
      child: binding == null
          ? DecoratedBox(
              // El ciruela y el crema de la paleta (ver `docs/UI_RIVE.md`).
              decoration: const ShapeDecoration(
                color: Color(0xFF8B2055),
                shape: StadiumBorder(),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    color: Color(0xFFFEF3D7),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          : SizedBox.fromSize(
              size: RiveBadge.size * scale,
              child: binding.widget(),
            ),
    );
  }
}
