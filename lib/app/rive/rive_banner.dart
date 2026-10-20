import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/app_theme.dart';
import 'package:guardianes_chacra/app/rive/rive_binding.dart';
import 'package:rive/rive.dart' as rive;

/// Los nombres del artboard `Banner` (ver `docs/UI_RIVE.md`).
abstract final class BannerRive {
  static const artboard = 'Banner';
  static const viewModel = 'Banner';

  /// "Oleada 3", ya traducido.
  static const title = 'title';

  /// La cinta roja de abajo (solo con [boss]).
  static const subtitle = 'subtitle';

  /// El cartel se pone rojo y aparece la cinta.
  static const boss = 'boss';

  /// Cae con un rebote, se queda ~2 s y sube desvaneciéndose (con menos
  /// movimiento, solo aparece y se va).
  static const show = 'show';
}

/// El cartel "Oleada N" que cae al empezar cada oleada, rojo y con aviso si
/// llega el jefe. No recibe toques: el mapa sigue respondiendo debajo.
///
/// Se muestra cada vez que sube [showCount]. Sin el archivo de Rive es un
/// cartel de Flutter que aparece y se desvanece igual de largo.
class RiveWaveBanner extends ConsumerStatefulWidget {
  const new({
    required this.title,
    required this.subtitle,
    required this.boss,
    required this.showCount,
    super.key,
  });

  final String title;
  final String subtitle;
  final bool boss;

  /// Cada vez que sube, el cartel se muestra (con 0 no se muestra).
  final int showCount;

  /// El artboard mide 360 × 150; en el HUD se dibuja algo más chico.
  static const Size size = Size(288, 120);

  /// Lo que se ve el cartel: entra, se queda y sale.
  static const duration = Duration(milliseconds: 2500);

  @override
  ConsumerState<RiveWaveBanner> createState() => _RiveWaveBannerState();
}

class _RiveWaveBannerState extends ConsumerState<RiveWaveBanner>
    with RiveBindingState<RiveWaveBanner> {
  rive.ViewModelInstanceTrigger? _show;

  /// Solo el respaldo: si el cartel está a la vista.
  bool _visible = false;
  Timer? _hide;

  @override
  String get artboardName => BannerRive.artboard;

  @override
  void bind(RiveBinding binding) {
    _show = binding.trigger(BannerRive.show);
    _apply(binding);
  }

  void _apply(RiveBinding binding) {
    binding.string(BannerRive.title).value = widget.title;
    binding.string(BannerRive.subtitle).value = widget.subtitle;
    binding.boolean(BannerRive.boss).value = widget.boss;
  }

  @override
  void didUpdateWidget(RiveWaveBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (binding case final binding?) _apply(binding);
    if (widget.showCount > oldWidget.showCount) _play();
  }

  void _play() {
    if (_show case final show?) {
      show.trigger();
      return;
    }
    _hide?.cancel();
    setState(() => _visible = true);
    _hide = Timer(RiveWaveBanner.duration, () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final binding = this.binding;
    final text = widget.boss
        ? '${widget.title}\n${widget.subtitle}'
        : widget.title;
    return IgnorePointer(
      child: Semantics(
        liveRegion: true,
        label: widget.showCount > 0 ? text : null,
        excludeSemantics: true,
        child: SizedBox.fromSize(
          size: RiveWaveBanner.size,
          child: binding != null
              ? binding.widget()
              : AnimatedOpacity(
                  opacity: _visible ? 1 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: Center(
                    child: _FallbackSign(text: text, boss: widget.boss),
                  ),
                ),
        ),
      ),
    );
  }
}

class _FallbackSign extends StatelessWidget {
  const new({required this.text, required this.boss});

  final String text;
  final bool boss;

  @override
  Widget build(BuildContext context) {
    final colors = GameColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: boss ? scheme.error : colors.hud,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: boss ? scheme.onError : colors.onHud,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
