import 'package:meta/meta.dart';

/// Las recompensas de los anuncios y cada cuánto puede aparecer uno
/// (`assets/content/ads.json`). Un 0 apaga esa parte.
@immutable
class AdsDef {
  const new({
    this.rewardedStartCorn = 0,
    this.rewardedRevivePotatoes = 0,
    this.interstitialEveryLevels = 0,
  });

  /// Maíz extra al empezar un nivel después de ver un anuncio.
  final int rewardedStartCorn;

  /// Papas con las que sigue la partida al revivir después de perder (una
  /// vez por partida).
  final int rewardedRevivePotatoes;

  /// Como máximo un intersticial cada tantas partidas terminadas.
  final int interstitialEveryLevels;
}
