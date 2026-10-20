import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/app/audio.dart';
import 'package:guardianes_chacra/app/haptics.dart';
import 'package:guardianes_chacra/app/rive/rive_badge.dart';
import 'package:guardianes_chacra/app/rive/rive_binding.dart';
import 'package:guardianes_chacra/app/rive/rive_icons.dart';
import 'package:guardianes_chacra/app/rive/rive_panel.dart';
import 'package:guardianes_chacra/app/rive/rive_segmented.dart';
import 'package:guardianes_chacra/app/rive/rive_star.dart';
import 'package:guardianes_chacra/app/rive/rive_tab.dart';
import 'package:guardianes_chacra/app/rive/rive_toggle.dart';
import 'package:guardianes_chacra/app/rive/rive_tooltip.dart';
import 'package:guardianes_chacra/app/rive/rive_ui.dart';
import 'package:guardianes_chacra/app/rive/rive_wave_bar.dart';
import 'package:guardianes_chacra/core/services/audio_service.dart';
import 'package:rive/rive.dart' as rive;

import '../../helpers/fake_audio_service.dart';
import '../../helpers/fake_haptics_service.dart';
import '../../helpers/test_app.dart' as helpers;

/// Los demás componentes del kit (Fase 3 de la interfaz): con el archivo de
/// Rive se dibujan en Rive; sin él, caen a un widget del tema. En los dos
/// casos responden igual al toque y a TalkBack.
///
/// Usa las librerías nativas de rive_native (ver `rive_contract_test.dart`).
void main() {
  late rive.File file;
  late FakeAudioService audio;

  setUpAll(() async {
    final bytes = await io.File(RiveUi.asset).readAsBytes();
    file = (await rive.File.decode(bytes, riveFactory: rive.Factory.flutter))!;
  });

  tearDownAll(() => file.dispose());

  setUp(() => audio = FakeAudioService());

  // En el juego van dentro de una pantalla: los respaldos (Switch, chips)
  // necesitan el Material del Scaffold.
  Widget testApp(Widget home, {List<Override> overrides = const []}) =>
      helpers.testApp(Scaffold(body: home), overrides: overrides);

  List<Override> services({required bool withRive}) => [
    audioServiceProvider.overrideWithValue(audio),
    hapticsServiceProvider.overrideWithValue(FakeHapticsService()),
    if (withRive) riveFileProvider.overrideWithValue(file),
  ];

  Matcher riveWidgets({required bool withRive}) =>
      withRive ? findsWidgets : findsNothing;

  for (final withRive in [false, true]) {
    final mode = withRive ? 'con Rive' : 'sin Rive';

    testWidgets('$mode: WaveBar sigue la oleada y avisa el jefe', (
      tester,
    ) async {
      Widget bar(int wave, {bool boss = false}) => testApp(
        Center(
          child: RiveWaveBar(
            wave: wave,
            totalWaves: 10,
            boss: boss,
            label: 'Oleada $wave/10',
            fallback: Text('Oleada $wave/10'),
          ),
        ),
        overrides: services(withRive: withRive),
      );

      await tester.pumpWidget(bar(2));
      expect(find.byType(rive.RiveWidget), riveWidgets(withRive: withRive));
      await tester.pumpWidget(bar(3));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpWidget(bar(10, boss: true));
      await tester.pump(const Duration(milliseconds: 900));

      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('Oleada 10/10'), findsOneWidget);
    });

    testWidgets('$mode: Star se llena y se vacía', (tester) async {
      Widget star({required bool filled}) => testApp(
        Center(child: RiveStar(filled: filled)),
        overrides: services(withRive: withRive),
      );

      await tester.pumpWidget(star(filled: false));
      await tester.pumpWidget(star(filled: true));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpWidget(star(filled: false));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byType(rive.RiveWidget), riveWidgets(withRive: withRive));
    });

    testWidgets('$mode: Toggle cambia con un toque, suena y es interruptor', (
      tester,
    ) async {
      var value = false;
      await tester.pumpWidget(
        testApp(
          StatefulBuilder(
            builder: (context, setState) => Center(
              child: RiveToggle(
                key: const ValueKey('toggle'),
                value: value,
                label: 'Vibración',
                onChanged: (on) => setState(() => value = on),
              ),
            ),
          ),
          overrides: services(withRive: withRive),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('toggle')));
      await tester.pump(const Duration(milliseconds: 300));

      expect(value, isTrue);
      expect(audio.sfx, [Sfx.uiTap]);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Vibración')),
        matchesSemantics(
          label: 'Vibración',
          hasToggledState: true,
          isToggled: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          // El Switch de respaldo también se enfoca con teclado.
          hasFocusAction: !withRive,
          isFocusable: !withRive,
        ),
      );
    });

    testWidgets('$mode: Segmented elige con un toque cada opción', (
      tester,
    ) async {
      var selected = 0;
      final keys = [for (var i = 0; i < 3; i++) ValueKey('option-$i')];
      await tester.pumpWidget(
        testApp(
          StatefulBuilder(
            builder: (context, setState) => Center(
              child: RiveSegmented(
                labels: const ['Sistema', 'Español', 'English'],
                selected: selected,
                optionKeys: keys,
                onChanged: (index) => setState(() => selected = index),
              ),
            ),
          ),
          overrides: services(withRive: withRive),
        ),
      );

      await tester.tap(find.byKey(keys[2]));
      await tester.pump(const Duration(milliseconds: 300));
      expect(selected, 2);
      await tester.tap(find.byKey(keys[1]));
      await tester.pump(const Duration(milliseconds: 300));
      expect(selected, 1);
      // Tocar la que ya está elegida no hace nada.
      await tester.tap(find.byKey(keys[1]));
      expect(audio.sfx, [Sfx.uiTap, Sfx.uiTap]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$mode: Tab se toca y dice si está elegida', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        testApp(
          Center(
            child: RiveTab(
              key: const ValueKey('tab'),
              label: 'Guardianes',
              icon: RiveIcon.shield,
              selected: true,
              onTap: () => taps++,
            ),
          ),
          overrides: services(withRive: withRive),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('tab')));
      expect(taps, 1);
      expect(audio.sfx, [Sfx.uiTap]);
      expect(find.byType(rive.RiveWidget), riveWidgets(withRive: withRive));
    });

    testWidgets('$mode: Tooltip aparece y se va sin tapar toques', (
      tester,
    ) async {
      Widget tip({required bool visible}) => testApp(
        Center(
          child: RiveTooltip(
            text: 'Toca otra vez para confirmar',
            visible: visible,
          ),
        ),
        overrides: services(withRive: withRive),
      );

      await tester.pumpWidget(tip(visible: false));
      expect(
        find.bySemanticsLabel('Toca otra vez para confirmar'),
        findsNothing,
      );
      await tester.pumpWidget(tip(visible: true));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.bySemanticsLabel('Toca otra vez para confirmar'),
        findsOneWidget,
      );
      await tester.pumpWidget(tip(visible: false));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });

    testWidgets('$mode: Badge muestra la etiqueta', (tester) async {
      await tester.pumpWidget(
        testApp(
          const Center(child: RiveBadge(label: '¡Nuevo!')),
          overrides: services(withRive: withRive),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.bySemanticsLabel('¡Nuevo!'), findsOneWidget);
      expect(find.byType(rive.RiveWidget), riveWidgets(withRive: withRive));
    });

    testWidgets('$mode: Panel entra y sale con su contenido', (tester) async {
      Widget panel({required bool visible}) => testApp(
        Center(
          child: SizedBox(
            width: 400,
            height: 220,
            child: RivePanel(visible: visible, child: const Text('Pausa')),
          ),
        ),
        overrides: services(withRive: withRive),
      );

      await tester.pumpWidget(panel(visible: true));
      await tester.pump(RivePanel.enter);
      expect(find.text('Pausa'), findsOneWidget);
      await tester.pumpWidget(panel(visible: false));
      await tester.pump(RivePanel.exit);

      expect(tester.takeException(), isNull);
      expect(find.byType(rive.RiveWidget), riveWidgets(withRive: withRive));
    });
  }

  // En el Redmi, al volver a entrar, el contenido subía desde abajo
  // mientras el marco caía desde arriba.
  testWidgets('el contenido del panel vuelve a entrar desde arriba', (
    tester,
  ) async {
    var taps = 0;
    Widget panel({required bool visible}) => testApp(
      Center(
        child: SizedBox(
          width: 400,
          height: 220,
          child: RivePanel(
            visible: visible,
            child: Center(
              child: TextButton(
                onPressed: () => taps++,
                child: const Text('Contenido'),
              ),
            ),
          ),
        ),
      ),
      overrides: services(withRive: true),
    );
    double top() => tester.getTopLeft(find.text('Contenido')).dy;

    await tester.pumpWidget(panel(visible: true));
    await tester.pump(RivePanel.enter);
    final rest = top();
    await tester.pumpWidget(panel(visible: false));
    await tester.pump(RivePanel.exit);
    // Oculto, no responde.
    await tester.tap(find.text('Contenido'), warnIfMissed: false);
    expect(taps, 0);

    await tester.pumpWidget(panel(visible: true));
    await tester.pump(const Duration(milliseconds: 30));
    expect(top(), lessThan(rest));
    await tester.pump(RivePanel.enter);
    expect(top(), closeTo(rest, 0.5));
  });

  // Rive no anima los layouts cuando el valor llega por data binding: lo
  // anima Flutter. En el Redmi la pastilla del selector saltaba.
  testWidgets('la pastilla del selector se desliza, no salta', (tester) async {
    final binding = RiveBinding.tryCreate(file, SegmentedRive.artboard)!;
    addTearDown(binding.dispose);
    final selected = binding.number(SegmentedRive.selected);
    final slide = RiveNumberTween(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 250),
    )..attach(selected, 0);
    addTearDown(slide.dispose);

    slide.animateTo(2, instant: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(selected.value, inExclusiveRange(0, 2));
    await tester.pump(const Duration(milliseconds: 200));
    expect(selected.value, 2);

    // Con menos movimiento, de golpe.
    slide.animateTo(0, instant: true);
    expect(selected.value, 0);
  });

  testWidgets('con menos movimiento, la oleada no anima pero sí cambia', (
    tester,
  ) async {
    Widget bar(int wave) => testApp(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Center(
          child: RiveWaveBar(
            wave: wave,
            totalWaves: 10,
            label: 'Oleada $wave/10',
            fallback: const SizedBox(),
          ),
        ),
      ),
      overrides: services(withRive: true),
    );

    await tester.pumpWidget(bar(1));
    await tester.pumpWidget(bar(2));
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('Oleada 2/10'), findsOneWidget);
  });
}
