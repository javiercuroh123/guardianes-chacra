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

/// Los nombres del artboard `IconSet` (ver `docs/UI_RIVE.md`).
abstract final class IconSetRive {
  static const artboard = 'IconSet';
  static const viewModel = 'IconSet';
  static const enumName = 'IconName';

  /// El ícono que se ve (un valor de [RiveIcon]).
  static const icon = 'icon';
}
