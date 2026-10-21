import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/app_theme.dart';
import 'package:guardianes_chacra/app/rive/rive_binding.dart';
import 'package:guardianes_chacra/app/rive/rive_icons.dart';

/// Un ícono del `IconSet` dibujado solo (por ejemplo, en los azulejos de
/// los ajustes). Es decoración: TalkBack no lo lee. Sin el archivo de Rive,
/// el ícono de Material más parecido.
class RiveIconView extends ConsumerStatefulWidget {
  const new(this.icon, {this.size = 32, super.key});

  final RiveIcon icon;

  /// Lado del ícono (el artboard mide 48 × 48).
  final double size;

  @override
  ConsumerState<RiveIconView> createState() => _RiveIconViewState();
}

class _RiveIconViewState extends ConsumerState<RiveIconView>
    with RiveBindingState<RiveIconView> {
  @override
  String get artboardName => IconSetRive.artboard;

  @override
  void bind(RiveBinding binding) =>
      binding.enumerator(IconSetRive.icon).value = widget.icon.name;

  @override
  void didUpdateWidget(RiveIconView oldWidget) {
    super.didUpdateWidget(oldWidget);
    binding?.viewModel.enumerator(IconSetRive.icon)?.value = widget.icon.name;
  }

  @override
  Widget build(BuildContext context) {
    final binding = this.binding;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: widget.size,
        child: binding != null
            ? binding.widget()
            : Icon(
                widget.icon.fallback,
                size: widget.size * 0.75,
                color: GameColors.of(context).onHud,
              ),
      ),
    );
  }
}
