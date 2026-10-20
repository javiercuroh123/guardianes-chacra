import 'package:flutter/material.dart';

/// Los íconos del artboard `IconSet` de Rive, en el mismo orden que el enum
/// `IconName` del archivo (el orden importa: cada ícono se elige por su
/// posición). Al agregar uno, va al final aquí y en el editor; el test de
/// contrato compara las dos listas.
///
/// Dart le pasa a Rive el nombre ([name]) como valor del enum.
enum RiveIcon {
  corn,
  potato,
  star,
  starEmpty,
  play,
  pause,
  fastForward,
  nextWave,
  gear,
  book,
  home,
  retry,
  back,
  close,
  lock,
  upgrade,
  sell,
  target,
  ground,
  air,
  music,
  sound,
  vibration,
  language,
  ad,
  check,
  flag,
  shield,
  damage,
}

/// El ícono de Material más parecido, para los respaldos de Flutter (sin el
/// archivo de Rive).
extension RiveIconFallback on RiveIcon {
  IconData get fallback => switch (this) {
    RiveIcon.corn => Icons.grass,
    RiveIcon.potato => Icons.egg_outlined,
    RiveIcon.star => Icons.star,
    RiveIcon.starEmpty => Icons.star_border,
    RiveIcon.play => Icons.play_arrow,
    RiveIcon.pause => Icons.pause,
    RiveIcon.fastForward => Icons.fast_forward,
    RiveIcon.nextWave => Icons.skip_next,
    RiveIcon.gear => Icons.settings,
    RiveIcon.book => Icons.menu_book,
    RiveIcon.home => Icons.home,
    RiveIcon.retry => Icons.refresh,
    RiveIcon.back => Icons.arrow_back,
    RiveIcon.close => Icons.close,
    RiveIcon.lock => Icons.lock,
    RiveIcon.upgrade => Icons.upgrade,
    RiveIcon.sell => Icons.sell,
    RiveIcon.target => Icons.gps_fixed,
    RiveIcon.ground => Icons.terrain,
    RiveIcon.air => Icons.air,
    RiveIcon.music => Icons.music_note,
    RiveIcon.sound => Icons.volume_up,
    RiveIcon.vibration => Icons.vibration,
    RiveIcon.language => Icons.language,
    RiveIcon.ad => Icons.ondemand_video,
    RiveIcon.check => Icons.check,
    RiveIcon.flag => Icons.flag,
    RiveIcon.shield => Icons.shield,
    RiveIcon.damage => Icons.flash_on,
  };
}

/// Los nombres del artboard `IconSet` (ver `docs/UI_RIVE.md`).
abstract final class IconSetRive {
  static const artboard = 'IconSet';
  static const viewModel = 'IconSet';
  static const enumName = 'IconName';

  /// El ícono que se ve (un valor de [RiveIcon]).
  static const icon = 'icon';
}
