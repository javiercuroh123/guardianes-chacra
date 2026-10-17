// Simulador de balance: juega cada nivel sin gráficos con las estrategias
// de `lib/dev/balance/autoplay.dart` y escribe un reporte CSV.
//
// Uso (desde la raíz del proyecto):
//
//     dart run tool/balance.dart
//
// Usa el contenido real de assets/ y la misma simulación que el juego. Como
// el dominio es Dart puro, corre sin Flutter y en pocos segundos.

import 'dart:io';

import 'package:guardianes_chacra/dev/balance/autoplay.dart';
import 'package:guardianes_chacra/features/content/data/content_loader.dart';
import 'package:guardianes_chacra/features/content/data/file_asset_source.dart';

Future<void> main() async {
  final content = await ContentLoader(FileAssetSource()).load();
  final watch = Stopwatch()..start();
  final results = runBalance(content);
  watch.stop();

  final report = File('build/balance/balance.csv');
  await report.parent.create(recursive: true);
  await report.writeAsString(balanceCsv(results));

  stdout.writeln(
    '${'Nivel'.padRight(18)}${'Estrategia'.padRight(11)}'
    '${'Resultado'.padRight(24)}${'Papas'.padRight(8)}'
    '${'Maíz sobrante'.padRight(15)}Guardianes',
  );
  for (final r in results) {
    final result = r.won
        ? 'gana'
        : 'pierde (oleada ${r.waveLost}/${r.totalWaves})';
    stdout.writeln(
      '${r.level.padRight(18)}${r.strategy.padRight(11)}'
      '${result.padRight(24)}'
      '${'${r.potatoesLeft}/${r.startingPotatoes}'.padRight(8)}'
      '${'${r.cornLeft}'.padRight(15)}${r.guardiansBuilt}',
    );
  }
  stdout
    ..writeln()
    ..writeln(
      '${results.length} partidas en ${watch.elapsedMilliseconds} ms. '
      'Reporte: ${report.path}',
    );
}
