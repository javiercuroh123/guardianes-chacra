import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/simulation.dart';
import 'package:guardianes_chacra/features/content/data/content_loader.dart';
import 'package:guardianes_chacra/features/content/data/file_asset_source.dart';
import 'package:guardianes_chacra/features/content/domain/game_content.dart';

import '../../helpers/scripted_defense.dart';

/// Comprobación rápida del balance: el nivel 1 se puede ganar con una
/// defensa razonable (no óptima). El simulador de la Fase 9 hará un
/// análisis completo.
void main() {
  late GameContent content;

  setUpAll(() async {
    content = await ContentLoader(FileAssetSource()).load();
  });

  test('la Chacra del Valle se gana con una defensa razonable', () {
    final level = content.levels.firstWhere(
      (level) => level.id == 'chacra_del_valle',
    );

    // Honderos en las curvas, una Tullpa contra enjambres y armaduras, un
    // Cóndor para los voladores y mejoras a medida que llega el maíz.
    final simulation = playScripted(content, level, const [
      Build('e3', 'hondero'),
      Build('e4', 'hondero'),
      Build('e1', 'hondero'),
      Build('e6', 'tullpa'),
      Upgrade('e3'),
      Upgrade('e4'),
      Build('e2', 'llama'),
      Upgrade('e6'),
      Build('e9', 'condor'),
      Upgrade('e1'),
      Upgrade('e3'),
      Upgrade('e4'),
      Build('e5', 'tullpa'),
      Upgrade('e6'),
      Specialize('e3', 'piedra_pesada'),
      Build('e7', 'hondero'),
      Upgrade('e9'),
      Specialize('e4', 'honda_rapida'),
      Upgrade('e5'),
      Upgrade('e7'),
    ]);

    expect(
      simulation.status,
      BattleStatus.won,
      reason:
          'quedaron ${simulation.potatoes} papas en la oleada '
          '${simulation.startedWaves}',
    );
    // Ganar raspando sería señal de un nivel 1 demasiado difícil.
    expect(simulation.potatoes, greaterThanOrEqualTo(15));
  });

  test('la Chacra del Valle no se gana con una defensa mínima', () {
    final level = content.levels.firstWhere(
      (level) => level.id == 'chacra_del_valle',
    );

    // Tres Honderos sin mejoras: si esto ganara, el nivel no tendría reto.
    final simulation = playScripted(content, level, const [
      Build('e3', 'hondero'),
      Build('e4', 'hondero'),
      Build('e1', 'hondero'),
    ]);

    expect(simulation.status, BattleStatus.lost);
  });
}
