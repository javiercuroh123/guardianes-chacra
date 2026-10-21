import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/app/curtain_route.dart';
import 'package:guardianes_chacra/app/rive/rive_curtain.dart';
import 'package:guardianes_chacra/app/rive/rive_ui.dart';
import 'package:rive/rive.dart' as rive;

import '../helpers/test_app.dart';

/// La cortina entre pantallas (Fase 8 de la interfaz): la pantalla nueva
/// aparece a la mitad, con la cortina cerrada, al ir y al volver; mientras
/// está tapada no se toca nada; con "menos movimiento", un fundido corto.
///
/// Usa las librerías nativas de rive_native (ver `rive_contract_test.dart`).
void main() {
  late rive.File file;

  setUpAll(() async {
    final bytes = await io.File(RiveUi.asset).readAsBytes();
    file = (await rive.File.decode(bytes, riveFactory: rive.Factory.flutter))!;
  });

  tearDownAll(() => file.dispose());

  test('la cortina está cerrada en la mitad de la ruta y abierta en los '
      'extremos', () {
    expect(RiveCurtain.coverAt(0), 0);
    expect(RiveCurtain.coverAt(1), 0);
    for (
      var t = RiveCurtain.closedFrom;
      t <= RiveCurtain.closedUntil;
      t += 0.02
    ) {
      expect(RiveCurtain.coverAt(t), 1, reason: 't = $t');
    }
    // Ya casi cerrada a un cuarto, y el rebote no se pasa mucho.
    expect(RiveCurtain.coverAt(0.25), greaterThan(0.9));
    for (var t = 0.0; t <= 1; t += 0.01) {
      expect(RiveCurtain.coverAt(t), lessThan(1.05), reason: 't = $t');
    }
  });

  /// Una pantalla con "Antes" (que cuenta sus toques) y un botón que abre
  /// "Nueva" con la cortina; "Nueva" tiene su botón para volver.
  Future<List<int>> pumpScreens(
    WidgetTester tester, {
    required bool withRive,
  }) async {
    final taps = [0];
    await tester.pumpWidget(
      testApp(
        Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                TextButton(
                  key: const ValueKey('before'),
                  onPressed: () => taps[0]++,
                  child: const Text('Antes'),
                ),
                TextButton(
                  key: const ValueKey('go'),
                  onPressed: () => Navigator.of(context).push(
                    CurtainRoute<void>(
                      builder: (context) => Scaffold(
                        body: TextButton(
                          key: const ValueKey('back'),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Nueva'),
                        ),
                      ),
                    ),
                  ),
                  child: const Text('Ir'),
                ),
              ],
            ),
          ),
        ),
        overrides: <Override>[
          if (withRive) riveFileProvider.overrideWithValue(file),
        ],
      ),
    );
    return taps;
  }

  double opacityOf(WidgetTester tester, String text) => tester
      .widget<Opacity>(
        find.ancestor(of: find.text(text), matching: find.byType(Opacity)),
      )
      .opacity;

  for (final withRive in [false, true]) {
    final mode = withRive ? 'con Rive' : 'sin Rive';

    testWidgets('$mode: la pantalla nueva aparece a la mitad, al ir y al '
        'volver', (tester) async {
      final taps = await pumpScreens(tester, withRive: withRive);

      await tester.tap(find.byKey(const ValueKey('go')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Tapada, y la cortina encima (de Rive o el fundido).
      expect(find.byType(RiveCurtain), findsOneWidget);
      expect(
        find.byType(rive.RiveWidget),
        withRive ? findsOneWidget : findsNothing,
      );
      // La pantalla nueva todavía no se armó: se arma con la cortina
      // cerrada.
      expect(find.text('Nueva'), findsNothing);
      // Mientras tanto, la de abajo no recibe toques.
      await tester.tap(find.text('Antes'), warnIfMissed: false);
      expect(taps[0], 0);

      await tester.pump(const Duration(milliseconds: 80));
      expect(opacityOf(tester, 'Nueva'), 0);

      await tester.pump(const Duration(milliseconds: 70));
      expect(opacityOf(tester, 'Nueva'), 1);

      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(RiveCurtain), findsNothing);
      // La de abajo ya no se dibuja.
      expect(find.text('Antes'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('back')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(RiveCurtain), findsOneWidget);
      expect(opacityOf(tester, 'Nueva'), 1);

      await tester.pump(const Duration(milliseconds: 150));
      expect(opacityOf(tester, 'Nueva'), 0);

      await tester.pumpAndSettle();
      expect(find.text('Nueva'), findsNothing);
      expect(find.byType(RiveCurtain), findsNothing);
      await tester.tap(find.text('Antes'));
      expect(taps[0], 1);
    });
  }

  test('el reloj de la ruta no salta: un cuadro lento avanza 34 ms', () {
    final clock = SteadyClock();
    expect(clock.tick(Duration.zero), Duration.zero);
    expect(
      clock.tick(const Duration(milliseconds: 8)),
      const Duration(milliseconds: 8),
    );
    // Un cuadro de 200 ms.
    expect(
      clock.tick(const Duration(milliseconds: 208)),
      const Duration(milliseconds: 42),
    );
    expect(
      clock.tick(const Duration(milliseconds: 216)),
      const Duration(milliseconds: 50),
    );
    // El ticker vuelve a arrancar (al volver): el reloj también.
    expect(clock.tick(Duration.zero), Duration.zero);
    expect(
      clock.tick(const Duration(milliseconds: 16)),
      const Duration(milliseconds: 16),
    );
  });

  testWidgets('con el reloj firme, un cuadro lento no se saltea la cortina', (
    tester,
  ) async {
    CurtainRoute.steadyClock = true;
    addTearDown(() => CurtainRoute.steadyClock = false);
    await pumpScreens(tester, withRive: true);

    await tester.tap(find.byKey(const ValueKey('go')));
    await tester.pump();
    // Un cuadro de medio segundo: con el reloj normal la ruta ya habría
    // terminado; con este, la cortina recién empieza a cerrarse.
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(RiveCurtain), findsOneWidget);
    expect(find.text('Nueva'), findsNothing);
    expect(find.text('Antes'), findsOneWidget);

    // Después, a 60 cuadros por segundo, termina.
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.byType(RiveCurtain), findsNothing);
    expect(find.text('Nueva'), findsOneWidget);
  });

  testWidgets('con "menos movimiento", un fundido corto y sin cortina', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpScreens(tester, withRive: true);

    await tester.tap(find.byKey(const ValueKey('go')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.byType(RiveCurtain), findsNothing);
    expect(
      find.ancestor(
        of: find.text('Nueva'),
        matching: find.byType(FadeTransition),
      ),
      findsWidgets,
    );

    await tester.pump(CurtainRoute.calmDuration);
    expect(find.text('Antes'), findsNothing);
    expect(find.text('Nueva'), findsOneWidget);
  });
}
