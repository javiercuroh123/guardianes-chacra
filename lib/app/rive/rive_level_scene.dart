import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/app_theme.dart';
import 'package:guardianes_chacra/app/rive/rive_binding.dart';
import 'package:guardianes_chacra/app/rive/rive_valley.dart';

/// Los nombres del artboard `LevelScene` (ver `docs/UI_RIVE.md`).
abstract final class LevelSceneRive {
  static const artboard = 'LevelScene';
  static const viewModel = 'LevelScene';
  static const enumName = 'LevelId';

  /// Qué parte del valle se ve: un valor del enum `LevelId`.
  static const level = 'level';

  /// La `Collca` anidada de los andenes (llena de papas).
  static const collca = 'collca';

  static const double aspect = 150 / 240;

  /// El radio de las esquinas del marco, como fracción del ancho.
  static const double cornerRadius = 14 / 240;

  /// El valor del enum `LevelId` de cada nivel del contenido.
  static const levels = <String, String>{
    'chacra_del_valle': 'chacra',
    'andenes': 'andenes',
    'orilla_del_lago': 'lago',
  };
}

/// La ilustración de un nivel: el mismo valle del título, encuadrado en la
/// chacra, en los andenes o en la orilla del lago, con un marco crema. Es
/// decoración: TalkBack no la lee. Sin el archivo de Rive (o para un nivel
/// que el dibujo no conoce), un paisaje de Flutter.
class RiveLevelScene extends ConsumerStatefulWidget {
  const new({required this.levelId, this.width = 96, super.key});

  final String levelId;

  /// Ancho (el artboard mide 240 × 150).
  final double width;

  @override
  ConsumerState<RiveLevelScene> createState() => _RiveLevelSceneState();
}

class _RiveLevelSceneState extends ConsumerState<RiveLevelScene>
    with RiveBindingState<RiveLevelScene> {
  @override
  String get artboardName => LevelSceneRive.artboard;

  @override
  void bind(RiveBinding binding) {
    final property = binding.enumerator(LevelSceneRive.level);
    // Un nivel que el dibujo no conoce usa el respaldo (ver build).
    property.value = LevelSceneRive.levels[widget.levelId] ?? property.value;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // La collca anidada tiene su propio "menos movimiento".
    binding?.viewModel
        .boolean('${LevelSceneRive.collca}/${RiveBinding.reduceMotion}')
        ?.value = MediaQuery.disableAnimationsOf(
      context,
    );
  }

  @override
  void didUpdateWidget(RiveLevelScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    final level = LevelSceneRive.levels[widget.levelId];
    if (level != null) {
      binding?.viewModel.enumerator(LevelSceneRive.level)?.value = level;
    }
  }

  @override
  Widget build(BuildContext context) {
    final binding = this.binding;
    final known = LevelSceneRive.levels.containsKey(widget.levelId);
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          widget.width * LevelSceneRive.cornerRadius,
        ),
        child: SizedBox(
          width: widget.width,
          height: widget.width * LevelSceneRive.aspect,
          child: binding != null && known
              ? binding.widget()
              : const _FallbackScene(),
        ),
      ),
    );
  }
}

/// Cielo, pasto y una montaña, con borde crema.
class _FallbackScene extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [RiveValley.sky, AppTheme.chacra],
        stops: [0.45, 0.55],
      ),
      border: Border.all(color: GameColors.of(context).hud, width: 3),
    ),
    child: const Center(
      child: Icon(Icons.landscape_rounded, color: Colors.white),
    ),
  );
}
