import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/app_theme.dart';
import 'package:guardianes_chacra/app/rive/rive_binding.dart';
import 'package:guardianes_chacra/app/rive/rive_icons.dart';
import 'package:guardianes_chacra/app/rive/rive_level_scene.dart';
import 'package:guardianes_chacra/app/rive/rive_portrait.dart';

/// Los nombres del artboard `UnlockCard` (ver `docs/UI_RIVE.md`).
abstract final class UnlockCardRive {
  static const artboard = 'UnlockCard';
  static const viewModel = 'UnlockCard';

  /// "Desbloqueado:".
  static const label = 'label';
  static const name = 'name';

  /// El `Portrait` anidado (un guardián) y la `LevelScene` anidada (un
  /// nivel).
  static const portrait = 'portrait';
  static const scene = 'scene';

  /// Muestra la escena en vez del retrato.
  static const isLevel = 'isLevel';

  /// Entra con un "pop" y el destello de atrás empieza a girar. Hasta
  /// entonces la tarjeta no se ve.
  static const enter = 'enter';
}

/// Lo que abrió una victoria: un guardián (su retrato) o un nivel (la
/// ilustración de su escena). Aparece con un "pop" cuando [shown] pasa a
/// `true`.
///
/// Sin el archivo de Rive, una tarjeta de Flutter que crece al aparecer.
class RiveUnlockCard extends ConsumerStatefulWidget {
  const new({
    required this.label,
    required this.name,
    required this.color,
    this.guardianId,
    this.levelId,
    this.shown = true,
    this.scale = 1,
    super.key,
  });

  final String label;
  final String name;

  /// El guardián desbloqueado; `null` si es un nivel.
  final String? guardianId;

  /// El nivel desbloqueado (para su escena); `null` si es un guardián.
  final String? levelId;

  /// El color del guardián (o del nivel), para el respaldo.
  final Color color;
  final bool shown;
  final double scale;

  /// El artboard a escala de letra 1.
  static const Size size = Size(280, 96);

  @override
  ConsumerState<RiveUnlockCard> createState() => _RiveUnlockCardState();
}

class _RiveUnlockCardState extends ConsumerState<RiveUnlockCard>
    with RiveBindingState<RiveUnlockCard> {
  @override
  String get artboardName => UnlockCardRive.artboard;

  @override
  void bind(RiveBinding binding) {
    final enter = binding.trigger(UnlockCardRive.enter);
    binding.string(UnlockCardRive.label).value = widget.label;
    binding.string(UnlockCardRive.name).value = widget.name;
    final guardianId = widget.guardianId;
    binding.boolean(UnlockCardRive.isLevel).value = guardianId == null;
    final scene = binding.enumerator(
      '${UnlockCardRive.scene}/${LevelSceneRive.level}',
    );
    scene.value = LevelSceneRive.levels[widget.levelId] ?? scene.value;
    binding
        .enumerator('${UnlockCardRive.portrait}/${PortraitRive.guardian}')
        .value = PortraitRive.valueFor(
      guardianId ?? PortraitRive.unknown,
    );
    if (widget.shown) enter.trigger();
  }

  @override
  void didUpdateWidget(RiveUnlockCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shown && !oldWidget.shown) {
      binding?.viewModel.trigger(UnlockCardRive.enter)?.trigger();
    }
  }

  @override
  Widget build(BuildContext context) {
    final binding = this.binding;
    final size =
        RiveUnlockCard.size *
        widget.scale *
        MediaQuery.textScalerOf(context).scale(1);
    return Semantics(
      container: true,
      label: widget.shown ? '${widget.label} ${widget.name}' : null,
      excludeSemantics: true,
      child: SizedBox.fromSize(
        size: size,
        child: binding != null ? binding.widget() : _fallback(context),
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    final colors = GameColors.of(context);
    final text = Theme.of(context).textTheme;
    return AnimatedScale(
      scale: widget.shown ? 1 : 0.3,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: widget.shown ? 1 : 0,
        duration: const Duration(milliseconds: 150),
        child: Card(
          child: Row(
            children: [
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 26,
                backgroundColor: widget.color,
                child: widget.guardianId == null
                    ? Icon(RiveIcon.flag.fallback, color: Colors.white)
                    : Text(
                        widget.name.characters.first.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.label, style: text.labelLarge),
                      Text(
                        widget.name,
                        style: text.titleLarge?.copyWith(
                          color: colors.star,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}
