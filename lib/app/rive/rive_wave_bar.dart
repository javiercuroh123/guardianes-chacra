import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/rive/rive_binding.dart';
import 'package:guardianes_chacra/app/rive/rive_icons.dart';
import 'package:rive/rive.dart' as rive;

/// Los nombres del artboard `WaveBar` (ver `docs/UI_RIVE.md`).
abstract final class WaveBarRive {
  static const artboard = 'WaveBar';
  static const viewModel = 'WaveBar';

  /// "Oleada 3/10", ya traducido.
  static const label = 'label';

  /// Cuánto se llenó la barra, de 0 a 1 (se llena con una animación).
  static const progress = 'progress';

  /// La oleada del jefe: la barra se pone roja y late un aviso.
  static const boss = 'boss';

  /// Empezó una oleada: el texto rebota y la pastilla destella.
  static const waveStarted = 'waveStarted';

  /// El `IconSet` anidado (la bandera).
  static const icon = 'icon';
}

/// La barra de oleadas del HUD: el texto, una barra que se llena y el aviso
/// del jefe. Al subir [wave] anima el inicio de la oleada, salvo que el
/// teléfono pida menos movimiento.
///
/// Es una barra continua y no por segmentos: los niveles tienen hasta 15
/// oleadas y los segmentos quedarían muy finos en un teléfono.
class RiveWaveBar extends ConsumerStatefulWidget {
  const new({
    required this.wave,
    required this.totalWaves,
    required this.label,
    required this.fallback,
    this.boss = false,
    this.width = 190,
    super.key,
  });

  final int wave;
  final int totalWaves;
  final String label;
  final bool boss;
  final Widget fallback;

  /// Ancho a escala de letra 1.
  final double width;

  static const double height = 40;

  @override
  ConsumerState<RiveWaveBar> createState() => _RiveWaveBarState();
}

class _RiveWaveBarState extends ConsumerState<RiveWaveBar>
    with RiveBindingState<RiveWaveBar> {
  rive.ViewModelInstanceString? _label;
  rive.ViewModelInstanceNumber? _progress;
  rive.ViewModelInstanceBoolean? _boss;
  rive.ViewModelInstanceTrigger? _waveStarted;

  double get _fill =>
      widget.totalWaves <= 0 ? 0 : widget.wave / widget.totalWaves;

  @override
  String get artboardName => WaveBarRive.artboard;

  @override
  void bind(RiveBinding binding) {
    binding.icon(WaveBarRive.icon).value = RiveIcon.flag.name;
    _label = binding.string(WaveBarRive.label)..value = widget.label;
    _progress = binding.number(WaveBarRive.progress)..value = _fill;
    _boss = binding.boolean(WaveBarRive.boss)..value = widget.boss;
    _waveStarted = binding.trigger(WaveBarRive.waveStarted);
  }

  @override
  void didUpdateWidget(RiveWaveBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (binding == null) return;
    _label?.value = widget.label;
    _progress?.value = _fill;
    _boss?.value = widget.boss;
    if (widget.wave > oldWidget.wave &&
        !MediaQuery.disableAnimationsOf(context)) {
      _waveStarted?.trigger();
    }
  }

  @override
  Widget build(BuildContext context) {
    final binding = this.binding;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return Semantics(
      label: widget.label,
      excludeSemantics: true,
      child: binding == null
          ? widget.fallback
          : SizedBox(
              width: widget.width * scale,
              height: RiveWaveBar.height * scale,
              child: binding.widget(fit: rive.Fit.layout, layoutScale: scale),
            ),
    );
  }
}
