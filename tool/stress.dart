// Prueba de estrés de la simulación: 150 plagas y 15 guardianes, sin
// gráficos. Mide cuánto tarda cada tick.
//
// Uso (desde la raíz del proyecto):
//
//     dart run tool/stress.dart
//
// Mide solo la lógica (la parte de Dart puro); el dibujo se mide en el
// teléfono con DevTools (ver docs/RENDIMIENTO.md).

import 'dart:io';

import 'package:guardianes_chacra/dev/stress.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/sim_time.dart';
import 'package:guardianes_chacra/features/content/data/content_loader.dart';
import 'package:guardianes_chacra/features/content/data/file_asset_source.dart';

/// A x2 se corren dos ticks por cuadro y, a 60 cuadros por segundo, cada
/// cuadro dura 16,7 ms (dibujo incluido). Que un tick tarde menos de 2 ms
/// deja más de tres cuartos del cuadro para dibujar.
const _budgetMs = 2.0;

Future<void> main() async {
  final content = await ContentLoader(FileAssetSource()).load();
  final report = runStress(content);

  String ms(double value) => '${value.toStringAsFixed(3)} ms';
  stdout
    ..writeln('Nivel: ${report.level}')
    ..writeln('Guardianes: ${report.guardians}')
    ..writeln('Plagas vivas a la vez (máximo): ${report.peakPests}')
    ..writeln(
      'Ticks medidos: ${report.ticks} '
      '(${report.ticks ~/ ticksPerSecond} s de juego)',
    )
    ..writeln()
    ..writeln('Tiempo por tick')
    ..writeln('  promedio: ${ms(report.averageMs)}')
    ..writeln('  p95:      ${ms(report.p95Ms)}')
    ..writeln('  máximo:   ${ms(report.maxMs)}')
    ..writeln()
    ..writeln(
      report.p95Ms <= _budgetMs
          ? 'Dentro del presupuesto (p95 ≤ ${ms(_budgetMs)}).'
          : 'Fuera del presupuesto: p95 > ${ms(_budgetMs)}. '
                'Revisa docs/RENDIMIENTO.md.',
    )
    ..writeln(
      'Ojo: `dart run` usa el compilador JIT de la computadora; en el '
      'teléfono (AOT, modo profile) los tiempos son otros.',
    );
}
