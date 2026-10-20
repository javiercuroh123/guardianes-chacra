import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/rive/rive_binding.dart';
import 'package:rive/rive.dart' as rive;

/// Los nombres del artboard `Portrait` (ver `docs/UI_RIVE.md`).
abstract final class PortraitRive {
  static const artboard = 'Portrait';
  static const viewModel = 'Portrait';
  static const enumName = 'GuardianId';

  /// Qué guardián se ve (un valor de [ids]).
  static const guardian = 'guardian';

  /// El retrato de respaldo: una silueta con "?".
  static const unknown = 'unknown';

  /// Los valores del enum `GuardianId`, en el orden del editor: el primero
  /// es el respaldo (un valor que el enum no tiene deja el primero).
  static const List<String> ids = [
    unknown,
    'hondero',
    'llama',
    'tullpa',
    'condor',
    'pututu',
  ];

  /// El valor para el guardián [guardianId]; si todavía no tiene retrato
  /// (un guardián nuevo en los datos), el de respaldo.
  static String valueFor(String guardianId) =>
      ids.contains(guardianId) ? guardianId : unknown;
}

/// El retrato de un guardián dibujado en Rive. Sin el archivo de Rive, un
/// círculo de [color] con la inicial de [name].
class RivePortrait extends ConsumerStatefulWidget {
  const new({
    required this.guardianId,
    required this.name,
    required this.color,
    this.size = 56,
    super.key,
  });

  final String guardianId;

  /// Para el respaldo y para TalkBack.
  final String name;
  final Color color;

  /// Lado a escala de letra 1.
  final double size;

  @override
  ConsumerState<RivePortrait> createState() => _RivePortraitState();
}

class _RivePortraitState extends ConsumerState<RivePortrait>
    with RiveBindingState<RivePortrait> {
  rive.ViewModelInstanceEnum? _guardian;

  @override
  String get artboardName => PortraitRive.artboard;

  @override
  void bind(RiveBinding binding) =>
      _guardian = binding.enumerator(PortraitRive.guardian)
        ..value = PortraitRive.valueFor(widget.guardianId);

  @override
  void didUpdateWidget(RivePortrait oldWidget) {
    super.didUpdateWidget(oldWidget);
    _guardian?.value = PortraitRive.valueFor(widget.guardianId);
  }

  @override
  Widget build(BuildContext context) {
    final side = MediaQuery.textScalerOf(context).scale(widget.size);
    final binding = this.binding;
    return Semantics(
      label: widget.name,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: side,
        child: binding != null
            ? binding.widget()
            : CircleAvatar(
                backgroundColor: widget.color,
                child: Text(
                  widget.name.characters.first.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: side * 0.4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      ),
    );
  }
}
