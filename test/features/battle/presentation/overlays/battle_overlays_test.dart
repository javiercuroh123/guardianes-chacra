import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/app/audio.dart';
import 'package:guardianes_chacra/app/haptics.dart';
import 'package:guardianes_chacra/app/rive/rive_button.dart';
import 'package:guardianes_chacra/app/rive/rive_ui.dart';
import 'package:guardianes_chacra/core/services/audio_service.dart';
import 'package:guardianes_chacra/core/services/haptics_service.dart';
import 'package:guardianes_chacra/features/battle/presentation/overlays/battle_overlays.dart';
import 'package:rive/rive.dart' as rive;

import '../../../../helpers/fake_audio_service.dart';
import '../../../../helpers/fake_haptics_service.dart';
import '../../../../helpers/test_app.dart';

/// La pausa, la victoria y la derrota (Fase 5 de la interfaz): el cartel,
/// la coreografía de la victoria y cuándo responden los botones. Cada
/// prueba de widgets corre con el archivo de Rive y sin él.
///
/// Usa las librerías nativas de rive_native (ver `rive_contract_test.dart`).
void main() {
  late rive.File file;
  late FakeAudioService audio;
  late FakeHapticsService haptics;

  setUpAll(() async {
    final bytes = await io.File(RiveUi.asset).readAsBytes();
    file = (await rive.File.decode(bytes, riveFactory: rive.Factory.flutter))!;
  });

  tearDownAll(() => file.dispose());

  setUp(() {
    audio = FakeAudioService();
    haptics = FakeHapticsService();
  });

  List<Override> services({required bool withRive}) => [
    audioServiceProvider.overrideWithValue(audio),
    hapticsServiceProvider.overrideWithValue(haptics),
    if (withRive) riveFileProvider.overrideWithValue(file),
  ];

  int starSounds() => audio.sfx.where((sfx) => sfx == Sfx.star).length;
  int starVibrations() =>
      haptics.vibrations.where((haptic) => haptic == Haptic.star).length;

  Finder key(String value) => find.byKey(ValueKey(value));

  group('VictoryTimeline', () {
    test('estrellas, conteo, desbloqueos y final, en ese orden', () {
      const timeline = VictoryTimeline(stars: 3, unlocks: 2);

      expect(
        [for (var i = 0; i < 3; i++) timeline.starAt(i)],
        [520, 900, 1280],
      );
      expect(timeline.countAt, 1740);
      expect(timeline.countEnd, 2440);
      expect([timeline.unlockAt(0), timeline.unlockAt(1)], [2640, 2900]);
      expect(timeline.finaleAt, 3200);

      expect(timeline.starsAt(899), 1);
      expect(timeline.starsAt(900), 2);
      expect(timeline.countProgressAt(2090), closeTo(0.5, 0.001));
      expect(timeline.unlocksAt(2700), 1);
    });

    test('sin desbloqueos, el final llega al terminar de contar', () {
      const timeline = VictoryTimeline(stars: 1, unlocks: 0);

      expect(timeline.countAt, 980);
      expect(timeline.finaleAt, timeline.countEnd + 150);
    });

    test('los botones responden antes de los 300 ms', () {
      expect(VictoryTimeline.buttonsAt, lessThanOrEqualTo(300));
    });
  });

  for (final withRive in [false, true]) {
    final mode = withRive ? 'con Rive' : 'sin Rive';

    group('$mode: victoria', () {
      var nexts = 0;

      setUp(() => nexts = 0);

      Widget victory({
        int stars = 3,
        List<UnlockedItem> unlocked = const [],
        bool calm = false,
      }) => Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: calm),
          child: Scaffold(
            body: VictoryOverlay(
              stars: stars,
              potatoes: 18,
              maxPotatoes: 20,
              cornHarvested: 480,
              unlocked: unlocked,
              onNext: () => nexts++,
              onRetry: () {},
              onExit: () {},
            ),
          ),
        ),
      );

      testWidgets('las estrellas se llenan una a una con sonido y vibración', (
        tester,
      ) async {
        await tester.pumpWidget(
          testApp(victory(stars: 2), overrides: services(withRive: withRive)),
        );
        expect(starSounds(), 0);

        await tester.pump(const Duration(milliseconds: 520));
        expect(starSounds(), 1);
        expect(starVibrations(), 1);

        await tester.pump(const Duration(milliseconds: 380));
        expect(starSounds(), 2);

        await tester.pump(const Duration(seconds: 3));
        expect(starSounds(), 2);
        expect(starVibrations(), 2);
        expect(find.bySemanticsLabel('2 de 3 estrellas'), findsOneWidget);
      });

      testWidgets('las papas y el maíz cuentan de cero al total', (
        tester,
      ) async {
        await tester.pumpWidget(
          testApp(victory(stars: 2), overrides: services(withRive: withRive)),
        );
        // El contenido del panel aparece en 130 ms (antes no se lee).
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.bySemanticsLabel('Papas restantes: 0/20'), findsOneWidget);

        // Dos estrellas: el conteo va de 1360 ms a 2060 ms.
        await tester.pump(const Duration(milliseconds: 1160));
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.bySemanticsLabel('Papas restantes: 9/20'), findsOneWidget);
        expect(find.bySemanticsLabel('Maíz cosechado: 240'), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 400));
        expect(find.bySemanticsLabel('Papas restantes: 18/20'), findsOneWidget);
        expect(find.bySemanticsLabel('Maíz cosechado: 480'), findsOneWidget);
      });

      testWidgets('los desbloqueos entran después del conteo', (tester) async {
        await tester.pumpWidget(
          testApp(
            victory(
              unlocked: const [
                UnlockedItem.level(
                  levelId: 'andenes',
                  name: 'Andenes',
                  color: Colors.teal,
                ),
                UnlockedItem.guardian(
                  guardianId: 'pututu',
                  name: 'Pututu',
                  color: Colors.orange,
                ),
              ],
            ),
            overrides: services(withRive: withRive),
          ),
        );
        expect(key('victory-unlocked'), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 2600));
        expect(find.bySemanticsLabel('Desbloqueado: Andenes'), findsNothing);

        await tester.pump(const Duration(milliseconds: 100));
        expect(find.bySemanticsLabel('Desbloqueado: Andenes'), findsOneWidget);
        expect(find.bySemanticsLabel('Desbloqueado: Pututu'), findsNothing);

        await tester.pump(const Duration(milliseconds: 300));
        expect(find.bySemanticsLabel('Desbloqueado: Pututu'), findsOneWidget);
      });

      testWidgets('los botones no responden hasta que cae el panel', (
        tester,
      ) async {
        await tester.pumpWidget(
          testApp(victory(), overrides: services(withRive: withRive)),
        );
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(key('victory-next'), warnIfMissed: false);
        expect(nexts, 0);

        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(key('victory-next'));
        expect(nexts, 1);
      });

      testWidgets('un toque fuera de los botones salta al final, sin sonido', (
        tester,
      ) async {
        await tester.pumpWidget(
          testApp(victory(), overrides: services(withRive: withRive)),
        );
        await tester.pump(const Duration(milliseconds: 600));
        expect(starSounds(), 1);

        await tester.tapAt(const Offset(4, 4));
        await tester.pump();
        expect(find.bySemanticsLabel('3 de 3 estrellas'), findsOneWidget);
        expect(find.bySemanticsLabel('Papas restantes: 18/20'), findsOneWidget);
        expect(starSounds(), 1);

        await tester.tap(key('victory-next'));
        expect(nexts, 1);
      });

      testWidgets('con menos movimiento se ve el final de una vez', (
        tester,
      ) async {
        await tester.pumpWidget(
          testApp(victory(calm: true), overrides: services(withRive: withRive)),
        );
        // Sin conteo ni estrellas una a una; el panel igual aparece en
        // 130 ms.
        await tester.pump(const Duration(milliseconds: 150));

        expect(find.bySemanticsLabel('Papas restantes: 18/20'), findsOneWidget);
        expect(starSounds(), 0);
        await tester.tap(key('victory-next'));
        expect(nexts, 1);
      });
    });

    testWidgets('$mode: la pausa tiene subtítulo y sus tres botones', (
      tester,
    ) async {
      var exits = 0;
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: PauseOverlay(
              onResume: () {},
              onRetry: () {},
              onExit: () => exits++,
            ),
          ),
          overrides: services(withRive: withRive),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.bySemanticsLabel('Pausa'), findsOneWidget);
      expect(find.text('La chacra puede esperar'), findsOneWidget);
      expect(key('pause-resume'), findsOneWidget);
      expect(key('battle-retry'), findsOneWidget);
      // Salir del nivel va en terracota.
      expect(tester.widget<RiveButton>(key('battle-exit')).danger, isTrue);

      await tester.tap(key('battle-exit'));
      expect(exits, 1);
    });

    testWidgets('$mode: la derrota ofrece el anuncio solo si lo hay', (
      tester,
    ) async {
      var revives = 0;
      Widget defeat({required bool ad}) => Scaffold(
        body: DefeatOverlay(
          potatoes: 0,
          maxPotatoes: 20,
          onRetry: () {},
          onExit: () {},
          onRevive: ad ? () => revives++ : null,
          revivePotatoes: 5,
        ),
      );

      await tester.pumpWidget(
        testApp(defeat(ad: false), overrides: services(withRive: withRive)),
      );
      await tester.pump(const Duration(milliseconds: 600));
      expect(
        find.bySemanticsLabel('La collca se quedó sin papas'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Papas restantes: 0/20'), findsOneWidget);
      expect(
        find.text('Prueba otra combinación de guardianes.'),
        findsOneWidget,
      );
      expect(key('battle-revive'), findsNothing);

      await tester.pumpWidget(
        testApp(defeat(ad: true), overrides: services(withRive: withRive)),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(key('battle-revive'));
      expect(revives, 1);
    });
  }
}
