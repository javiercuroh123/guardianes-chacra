import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/app_theme.dart';
import 'package:guardianes_chacra/app/rive/rive_binding.dart';
import 'package:rive/rive.dart' as rive;

/// Los nombres del artboard `Valley` (ver `docs/UI_RIVE.md`).
abstract final class ValleyRive {
  static const artboard = 'Valley';
  static const viewModel = 'Valley';

  /// La `Collca` anidada de los andenes (llena de papas).
  static const collca = 'collca';

  /// Lo que mide el artboard: el paisaje se dibuja cubriendo a su padre.
  static const Size size = Size(960, 432);
}

/// El valle en capas (cielo, nubes que cruzan, cordillera, lago, andenes
/// con la collca, chacra y plantas delante), de fondo del título y del
/// mapa. Cubre a su padre, no recibe toques y TalkBack no lo lee. Sin el
/// archivo de Rive, el verde de la chacra con un cielo degradado.
class RiveValley extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<RiveValley> createState() => _RiveValleyState();
}

class _RiveValleyState extends ConsumerState<RiveValley>
    with RiveBindingState<RiveValley> {
  @override
  String get artboardName => ValleyRive.artboard;

  @override
  void bind(RiveBinding binding) {}

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // La collca anidada tiene su propio "menos movimiento" (el polvo).
    binding?.viewModel
        .boolean('${ValleyRive.collca}/${RiveBinding.reduceMotion}')
        ?.value = MediaQuery.disableAnimationsOf(
      context,
    );
  }

  @override
  Widget build(BuildContext context) {
    final binding = this.binding;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: binding != null
            ? binding.widget(fit: rive.Fit.cover)
            : const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF8ED0F0), AppTheme.chacra],
                    stops: [0.25, 0.6],
                  ),
                ),
              ),
      ),
    );
  }
}
