import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/rive/rive_binding.dart';
import 'package:guardianes_chacra/app/ui_feedback.dart';

/// Los nombres del artboard `Toggle` (ver `docs/UI_RIVE.md`).
abstract final class ToggleRive {
  static const artboard = 'Toggle';
  static const viewModel = 'Toggle';

  /// Encendido: la perilla cruza con un squash y el riel se pone verde.
  static const on = 'on';
  static const enabled = 'enabled';
}

/// Un interruptor dibujado en Rive. Flutter recibe el toque (con su
/// Semantics de interruptor), toca el sonido y vibra. Sin [onChanged] queda
/// deshabilitado. Sin el archivo de Rive es un `Switch` del tema.
class RiveToggle extends ConsumerStatefulWidget {
  const new({
    required this.value,
    required this.onChanged,
    required this.label,
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Lo que lee TalkBack (el texto que lo acompaña en pantalla).
  final String label;

  static const Size size = Size(60, 36);

  @override
  ConsumerState<RiveToggle> createState() => _RiveToggleState();
}

class _RiveToggleState extends ConsumerState<RiveToggle>
    with RiveBindingState<RiveToggle> {
  @override
  String get artboardName => ToggleRive.artboard;

  @override
  void bind(RiveBinding binding) {
    binding.boolean(ToggleRive.on).value = widget.value;
    binding.boolean(ToggleRive.enabled).value = widget.onChanged != null;
  }

  @override
  void didUpdateWidget(RiveToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (binding case final binding?) bind(binding);
  }

  void _toggle() {
    ref.read(uiFeedbackProvider).tap();
    widget.onChanged?.call(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final binding = this.binding;
    final enabled = widget.onChanged != null;
    if (binding == null) {
      return Semantics(
        label: widget.label,
        child: Switch(
          value: widget.value,
          onChanged: enabled ? (_) => _toggle() : null,
        ),
      );
    }
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return Semantics(
      toggled: widget.value,
      enabled: enabled,
      label: widget.label,
      onTap: enabled ? _toggle : null,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? _toggle : null,
        // 48 de alto para el pulgar, aunque el dibujo sea más bajo.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Center(
            widthFactor: 1,
            child: SizedBox(
              width: RiveToggle.size.width * scale,
              height: RiveToggle.size.height * scale,
              child: binding.widget(),
            ),
          ),
        ),
      ),
    );
  }
}
