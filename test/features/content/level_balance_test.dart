import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/dev/balance/autoplay.dart';
import 'package:guardianes_chacra/features/content/data/content_loader.dart';
import 'package:guardianes_chacra/features/content/data/file_asset_source.dart';
import 'package:guardianes_chacra/features/content/domain/game_content.dart';

/// El balance mínimo que no debe romperse al tocar los datos, con las
/// estrategias del simulador (`dart run tool/balance.dart` da el detalle;
/// ver `docs/BALANCE.md`).
void main() {
  late GameContent content;
  late List<AutoplayResult> results;

  setUpAll(() async {
    content = await ContentLoader(FileAssetSource()).load();
    results = runBalance(content);
  });

  AutoplayResult result(String level, String strategy) =>
      results.firstWhere((r) => r.level == level && r.strategy == strategy);

  test('cada nivel se puede ganar con una defensa razonable', () {
    for (final level in content.levels) {
      final honderos = result(level.id, 'honderos');
      expect(honderos.won, isTrue, reason: level.id);
      // Ganar raspando sería señal de un nivel demasiado difícil.
      expect(honderos.potatoesLeft, greaterThanOrEqualTo(15), reason: level.id);
    }
  });

  test('ningún nivel se gana con una defensa mínima', () {
    for (final level in content.levels) {
      expect(result(level.id, 'minima').won, isFalse, reason: level.id);
    }
  });

  test('el primer nivel perdona una defensa mezclada', () {
    expect(result('chacra_del_valle', 'mixta').won, isTrue);
    expect(result('chacra_del_valle', 'mejoras').won, isTrue);
  });

  test('el simulador escribe una fila por partida', () {
    final csv = balanceCsv(results).trim().split('\n');

    expect(csv.first, startsWith('nivel,estrategia,resultado'));
    expect(csv, hasLength(1 + content.levels.length * 4));
  });

  test('con varios caminos, los primeros espacios cubren a cada uno', () {
    final andenes = content.levels.firstWhere((l) => l.id == 'andenes');
    final ranking = rankSlotsByCoverage(andenes);

    // e2 cubre el tramo propio del norte y e4 el del sur: van primero,
    // antes que los del tramo compartido junto a la collca.
    expect(ranking.take(2), ['e2', 'e4']);
  });
}
