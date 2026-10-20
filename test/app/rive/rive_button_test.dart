import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/app/audio.dart';
import 'package:guardianes_chacra/app/haptics.dart';
import 'package:guardianes_chacra/app/rive/rive_button.dart';
import 'package:guardianes_chacra/app/rive/rive_icons.dart';
import 'package:guardianes_chacra/app/rive/rive_ui.dart';
import 'package:guardianes_chacra/core/services/audio_service.dart';
import 'package:guardianes_chacra/core/services/haptics_service.dart';
import 'package:guardianes_chacra/features/progress/domain/progress_repository.dart';
import 'package:guardianes_chacra/features/progress/presentation/save_providers.dart';
import 'package:guardianes_chacra/features/settings/domain/settings.dart';
import 'package:rive/rive.dart' as rive;

import '../../helpers/fake_audio_service.dart';
import '../../helpers/fake_haptics_service.dart';
import '../../helpers/test_app.dart';

/// Los botones de Rive: Flutter recibe el toque (Key, Semantics), toca el
/// sonido y vibra; Rive anima. Sin el archivo, los botones del tema hacen lo
/// mismo.
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

  List<Override> services({bool withRive = false, bool vibration = true}) => [
    audioServiceProvider.overrideWithValue(audio),
    hapticsServiceProvider.overrideWithValue(haptics),
    savedGameProvider.overrideWithValue(
      SaveData(settings: Settings(vibration: vibration)),
    ),
    if (withRive) riveFileProvider.overrideWithValue(file),
  ];

  const key = ValueKey('button');

  for (final withRive in [false, true]) {
    final mode = withRive ? 'con Rive' : 'sin Rive';

    testWidgets('$mode: tocarlo llama a onPressed, suena y vibra', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        testApp(
          Center(
            child: RiveButton(
              key: key,
              label: 'Jugar',
              icon: RiveIcon.play,
              onPressed: () => taps++,
            ),
          ),
          overrides: services(withRive: withRive),
        ),
      );

      expect(
        find.byType(rive.RiveWidget),
        withRive ? findsOneWidget : findsNothing,
      );
      expect(find.bySemanticsLabel('Jugar'), findsOneWidget);

      await tester.tap(find.byKey(key));
      await tester.pump(const Duration(milliseconds: 400));

      expect(taps, 1);
      expect(audio.sfx, [Sfx.uiTap]);
      expect(haptics.vibrations, [Haptic.tap]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$mode: sin maíz se sacude, avisa y no hace la acción', (
      tester,
    ) async {
      var denied = 0;
      await tester.pumpWidget(
        testApp(
          Center(
            child: RiveButton(
              key: key,
              label: 'Mejorar',
              icon: RiveIcon.upgrade,
              onPressed: null,
              onDenied: () => denied++,
            ),
          ),
          overrides: services(withRive: withRive),
        ),
      );

      await tester.tap(find.byKey(key));
      await tester.pump(const Duration(milliseconds: 400));

      expect(denied, 1);
      expect(audio.sfx, [Sfx.uiDeny]);
      expect(haptics.vibrations, [Haptic.deny]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$mode: deshabilitado y sin aviso, no responde', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          const Center(
            child: RiveButton(
              key: key,
              kind: RiveButtonKind.secondary,
              label: 'Mejorar',
              onPressed: null,
            ),
          ),
          overrides: services(withRive: withRive),
        ),
      );

      await tester.tap(find.byKey(key), warnIfMissed: false);
      await tester.pump();

      expect(audio.sfx, isEmpty);
      expect(haptics.vibrations, isEmpty);
    });

    testWidgets('$mode: redondo, con tooltip y en rojo', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        testApp(
          Center(
            child: RiveButton.round(
              key: key,
              label: 'Cerrar',
              icon: RiveIcon.close,
              danger: true,
              onPressed: () => taps++,
            ),
          ),
          overrides: services(withRive: withRive),
        ),
      );

      expect(find.byTooltip('Cerrar'), findsOneWidget);
      await tester.tap(find.byKey(key));
      expect(taps, 1);
    });
  }

  testWidgets('con la vibración apagada solo suena', (tester) async {
    await tester.pumpWidget(
      testApp(
        Center(
          child: RiveButton(key: key, label: 'Jugar', onPressed: () {}),
        ),
        overrides: services(vibration: false),
      ),
    );

    await tester.tap(find.byKey(key));

    expect(audio.sfx, [Sfx.uiTap]);
    expect(haptics.vibrations, isEmpty);
  });

  testWidgets('presionar y soltar anima sin romperse', (tester) async {
    await tester.pumpWidget(
      testApp(
        Center(
          child: RiveButton(key: key, label: 'Jugar', onPressed: () {}),
        ),
        overrides: services(withRive: true),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(key)),
    );
    await tester.pump(const Duration(milliseconds: 120));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
  });

  testWidgets('el ancho sigue al texto y crece con la letra grande', (
    tester,
  ) async {
    Future<Size> sizeOf(String label) async {
      await tester.pumpWidget(
        testApp(
          Center(
            child: RiveButton(
              key: key,
              label: label,
              icon: RiveIcon.play,
              onPressed: () {},
            ),
          ),
          overrides: services(withRive: true),
        ),
      );
      return tester.getSize(find.byKey(key));
    }

    final short = await sizeOf('OK');
    final long = await sizeOf('Recuperar papas con un anuncio');
    expect(short.width, RiveButton.minWidth);
    expect(long.width, greaterThan(short.width));
    expect(short.height, RiveButton.height);

    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final big = await sizeOf('OK');
    expect(big.height, closeTo(RiveButton.height * 1.5, 0.01));
  });

  // Como en el contador: si la letra del .riv no tuviera los glifos, el
  // botón saldría sin texto y ningún otro test lo notaría.
  testWidgets('el texto se dibuja de verdad', (tester) async {
    final boundary = GlobalKey();
    await tester.pumpWidget(
      testApp(
        Center(
          child: RepaintBoundary(
            key: boundary,
            child: RiveButton(
              kind: RiveButtonKind.secondary,
              label: 'Bestiario',
              onPressed: () {},
            ),
          ),
        ),
        overrides: services(withRive: true),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    final dark = await tester.runAsync(() async {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 2);
      final bytes = (await image.toByteData())!;
      var count = 0;
      // Solo la franja del centro: los bordes también son oscuros.
      for (var y = image.height ~/ 3; y < image.height * 2 ~/ 3; y++) {
        for (var x = image.width ~/ 4; x < image.width * 3 ~/ 4; x++) {
          final i = (y * image.width + x) * 4;
          final isText =
              bytes.getUint8(i) < 110 &&
              bytes.getUint8(i + 1) < 60 &&
              bytes.getUint8(i + 2) < 40 &&
              bytes.getUint8(i + 3) > 200;
          if (isText) count++;
        }
      }
      return count;
    });

    expect(dark, greaterThan(150));
  });
}
