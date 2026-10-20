import 'package:flutter/material.dart' hide Simulation;
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/app/app_theme.dart';
import 'package:guardianes_chacra/app/rive/rive_banner.dart';
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
          // Los mismos lugares que les da `BattleScreen`.
          body: Stack(
            children: [
              Positioned(
                top: 4,
                left: 6,
                right: 6,
                child: BattleHud(
                  onToggleSpeed: () => taps.add('speed'),
                  onPause: () => taps.add('pause'),
                  onDevTools: devTools ? () => taps.add('dev') : null,
                ),
              ),
              const Positioned(
                top: 52,
                left: 0,
                right: 0,
                child: Center(child: BattleWaveBanner()),
              ),
              Positioned(
                right: 8,
                bottom: 8,
                child: BattleNextWave(onNextWave: () => taps.add('next')),
              ),
            ],
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

  /// Cuánto se ve el cartel de respaldo.
  double bannerOpacity(WidgetTester tester) => tester
      .widget<AnimatedOpacity>(
        find.descendant(
          of: find.byType(RiveWaveBanner),
          matching: find.byType(AnimatedOpacity),
        ),
      )
      .opacity;

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
    // Sin máximo propio, el máximo son las papas del estado.
    expect(find.text('🥔 20/20'), findsOneWidget);
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
    expect(
      find.bySemanticsLabel('Papas en la collca: 20 de 20'),
      findsOneWidget,
    );
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

  testWidgets(
    'las papas se muestran sobre el máximo y avisan si quedan pocas',
    (tester) async {
      const few = BattleHudState(
        corn: 40,
        potatoes: 3,
        maxPotatoes: 10,
        wave: 4,
        totalWaves: 10,
        status: BattleStatus.playing,
      );
      expect(few.lowPotatoes, isTrue);
      expect(playing.lowPotatoes, isFalse);

      await pumpHud(tester, few);

      expect(find.text('🥔 3/10'), findsOneWidget);
    },
  );

  testWidgets('al empezar una oleada cae el cartel, rojo si trae al jefe', (
    tester,
  ) async {
    await pumpHud(tester, playing.copyForTest(startedWaves: 2));
    // Al montarse no se muestra (por ejemplo, al volver de la pausa).
    expect(bannerOpacity(tester), 0);

    containerOf(tester, Scaffold).read(battleHudProvider.notifier).hud = playing
        .copyForTest(startedWaves: 3, wave: 3, boss: true);
    await tester.pump();

    expect(bannerOpacity(tester), 1);
    expect(find.text('Oleada 3\n¡Llega el jefe!'), findsOneWidget);

    // Se va solo.
    await tester.pump(const Duration(seconds: 3));
    expect(bannerOpacity(tester), 0);
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

extension on BattleHudState {
  BattleHudState copyForTest({
    required int startedWaves,
    int? wave,
    bool boss = false,
  }) => BattleHudState(
    corn: corn,
    potatoes: potatoes,
    maxPotatoes: maxPotatoes,
    wave: wave ?? this.wave,
    totalWaves: totalWaves,
    startedWaves: startedWaves,
    boss: boss,
    status: status,
    nextWaveSeconds: nextWaveSeconds,
    nextWaveTotalSeconds: nextWaveTotalSeconds,
    earlyCallBonus: earlyCallBonus,
    speed: speed,
  );
}
