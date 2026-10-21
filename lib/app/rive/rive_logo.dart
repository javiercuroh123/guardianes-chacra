import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/rive/rive_binding.dart';

/// Los nombres del artboard `Logo` (ver `docs/UI_RIVE.md`).
abstract final class LogoRive {
  static const artboard = 'Logo';
  static const viewModel = 'Logo';

  /// Las tres líneas del nombre ("GUARDIANES", "DE LA", "CHACRA") y el lema
  /// de la cinta.
  static const line1 = 'line1';
  static const line2 = 'line2';
  static const line3 = 'line3';
  static const tagline = 'tagline';

  static const double aspect = 250 / 520;
}

/// El logo del título: el cartel de madera cae, las líneas del nombre
/// bajan una tras otra, la cinta del lema hace "pop" y las hojas y las
/// mazorcas se mecen. TalkBack lee [title] y [tagline].
///
/// Sin el archivo de Rive, el nombre y el lema con el estilo del tema.
class RiveLogo extends ConsumerStatefulWidget {
  const new({
    required this.title,
    required this.lines,
    required this.tagline,
    this.width = 360,
    super.key,
  });

  /// El nombre en una línea, para TalkBack y el respaldo.
  final String title;

  /// El nombre partido en las tres líneas del cartel.
  final (String, String, String) lines;
  final String tagline;

  /// Ancho a escala de letra 1 (el artboard mide 520 × 250).
  final double width;

  @override
  ConsumerState<RiveLogo> createState() => _RiveLogoState();
}

class _RiveLogoState extends ConsumerState<RiveLogo>
    with RiveBindingState<RiveLogo> {
  @override
  String get artboardName => LogoRive.artboard;

  @override
  void bind(RiveBinding binding) => _apply(binding);

  void _apply(RiveBinding binding) {
    final (line1, line2, line3) = widget.lines;
    binding.string(LogoRive.line1).value = line1;
    binding.string(LogoRive.line2).value = line2;
    binding.string(LogoRive.line3).value = line3;
    binding.string(LogoRive.tagline).value = widget.tagline;
  }

  @override
  void didUpdateWidget(RiveLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (binding case final binding?) _apply(binding);
  }

  @override
  Widget build(BuildContext context) {
    final binding = this.binding;
    if (binding == null) return _fallback(context);
    final width = MediaQuery.textScalerOf(context).scale(widget.width);
    return Semantics(
      header: true,
      label: '${widget.title}. ${widget.tagline}',
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        height: width * LogoRive.aspect,
        child: binding.widget(),
      ),
    );
  }

  /// El título de siempre: el nombre grande en blanco y el lema debajo.
  Widget _fallback(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.title,
          textAlign: TextAlign.center,
          style: textTheme.displayMedium?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(
          widget.tagline,
          textAlign: TextAlign.center,
          style: textTheme.titleLarge?.copyWith(color: const Color(0xFFFFF3C4)),
        ),
      ],
    );
  }
}
