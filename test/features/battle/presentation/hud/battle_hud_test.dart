import 'package:flutter/material.dart' hide Simulation;
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/app/app_theme.dart';
import 'package:guardianes_chacra/app/text_scale.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/fixed_step_clock.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/simulation.dart';
import 'package:guardianes_chacra/features/battle/presentation/hud/battle_hud.dart';
import 'package:guardianes_chacra/features/battle/presentation/hud/battle_hud_state.dart';

import '../../../../helpers/battle_game_helpers.dart';
import '../../../../helpers/test_app.dart';

/// El HUD solo muestra `battleHudProvider`: cada test pone un estado y mira
/// qué se ve y qué avisa al tocar.
void main() {
  const playing = BattleHudState(
    corn: 220,
    potatoes: 20,
    wave: 3,
    totalWaves: 10,
    status: BattleStatus.playing,
    nextWaveSeconds: 12,
    earlyCallBonus: 18,
  );

  late List<String> taps;

  Future<void> pumpHud(
    WidgetTester tester,
    BattleHudState? state, {
    bool devTools = false,
  }) async {
    usePhoneLandscape(tester);
    taps = [];
    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            // El mismo margen que le deja `BattleScreen`.
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: BattleHud(
                onNextWave: () => taps.add('next'),
                onToggleSpeed: () => taps.add('speed'),
                onPause: () => taps.add('pause'),
                onDevTools: devTools ? () => taps.add('dev') : null,
              ),
            ),
          ),
        ),
      ),
    );
    if (state != null) {
      containerOf(tester, Scaffold).read(battleHudProvider.notifier).hud =
          state;
      await tester.pump();
    }
  }

  Finder key(String value) => find.byKey(ValueKey(value));

  testWidgets('sin estado (antes del primer cuadro) no muestra nada', (
    tester,
  ) async {
    await pumpHud(tester, null);

    expect(key('hud-corn'), findsNothing);
    expect(key('hud-pause'), findsNothing);
  });

  testWidgets('muestra maíz, papas, oleada y la llamada anticipada', (
    tester,
  ) async {
    await pumpHud(tester, playing);

    expect(find.text('🌽 220'), findsOneWidget);
    expect(find.text('🥔 20'), findsOneWidget);
    expect(find.text('Oleada 3/10'), findsOneWidget);
    expect(find.text('12 s'), findsOneWidget);
    expect(find.text('+18'), findsOneWidget);
    expect(find.text('x1'), findsOneWidget);
  });

  testWidgets('sin oleada en cuenta regresiva no se puede llamar', (
    tester,
  ) async {
    await pumpHud(
      tester,
      const BattleHudState(
        corn: 40,
        potatoes: 7,
        wave: 10,
        totalWaves: 10,
        status: BattleStatus.playing,
      ),
    );

    expect(key('hud-next-wave'), findsNothing);
    expect(find.text('Oleada 10/10'), findsOneWidget);
  });

  testWidgets('a x2 el botón se pinta de maíz', (tester) async {
    await pumpHud(
      tester,
      const BattleHudState(
        corn: 220,
        potatoes: 20,
        wave: 1,
        totalWaves: 10,
        status: BattleStatus.playing,
        speed: GameSpeed.fast,
      ),
    );

    final text = tester.widget<Text>(find.text('x2'));
    expect(text.style?.color, AppTheme.light.colorScheme.onSecondary);
    expect(find.text('x1'), findsNothing);
  });

  testWidgets('cada botón avisa su toque', (tester) async {
    await pumpHud(tester, playing, devTools: true);

    await tester.tap(key('hud-next-wave'));
    await tester.tap(key('hud-speed'));
    await tester.tap(key('hud-dev'));
    await tester.tap(key('hud-pause'));

    expect(taps, ['next', 'speed', 'dev', 'pause']);
  });

  testWidgets('el botón de desarrollo solo aparece si se pide', (tester) async {
    await pumpHud(tester, playing);

    expect(key('hud-dev'), findsNothing);
  });

  testWidgets('los lectores de pantalla leen cada dato completo', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpHud(tester, playing);

    expect(find.bySemanticsLabel('Maíz: 220'), findsOneWidget);
    expect(find.bySemanticsLabel('Papas en la collca: 20'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Llamar la siguiente oleada ahora: faltan 12 s, ganas 18 de maíz',
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('Velocidad x1'), findsOneWidget);
    expect(find.byTooltip('Pausa'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('los botones se pueden tocar con el dedo (48 × 48)', (
    tester,
  ) async {
    await pumpHud(tester, playing, devTools: true);

    for (final button in [
      'hud-next-wave',
      'hud-speed',
      'hud-dev',
      'hud-pause',
    ]) {
      final size = tester.getSize(key(button));
      expect(size.height, greaterThanOrEqualTo(48), reason: button);
      expect(size.width, greaterThanOrEqualTo(48), reason: button);
    }
  });

  testWidgets('con letra grande crece hasta 1,3 y cabe en el teléfono', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    // Los números más largos que pueden aparecer.
    await pumpHud(
      tester,
      const BattleHudState(
        corn: 9999,
        potatoes: 20,
        wave: 15,
        totalWaves: 15,
        status: BattleStatus.playing,
        nextWaveSeconds: 30,
        earlyCallBonus: 45,
      ),
      devTools: true,
    );

    expect(tester.takeException(), isNull);
    final context = tester.element(find.text('🌽 9999'));
    expect(
      MediaQuery.textScalerOf(context).scale(10),
      closeTo(10 * TextScaleLimits.battle, 1e-9),
    );
  });
}
