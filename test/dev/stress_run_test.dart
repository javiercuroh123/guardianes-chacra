import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/dev/stress.dart';

import '../helpers/real_content.dart';

void main() {
  final content = useRealContent();

  test('la prueba de estrés llena el mapa de plagas y guardianes', () {
    // Más corta que la de `tool/stress.dart`: aquí importa que funcione,
    // no cuánto tarda (eso depende de la computadora).
    final report = runStress(content(), pests: 60, seconds: 6);

    // Ningún mapa tiene 15 espacios: se agregan los que faltan.
    expect(report.guardians, 15);
    expect(report.peakPests, greaterThanOrEqualTo(40));
    expect(report.ticks, 5 * 30);
    expect(report.averageMs, greaterThan(0));
    expect(report.maxMs, greaterThanOrEqualTo(report.p95Ms));
  });
}
