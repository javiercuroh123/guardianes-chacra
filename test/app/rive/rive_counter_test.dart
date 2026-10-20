import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/app/rive/rive_counter.dart';
import 'package:guardianes_chacra/app/rive/rive_icons.dart';
import 'package:guardianes_chacra/app/rive/rive_ui.dart';
import 'package:rive/rive.dart' as rive;

import '../../helpers/test_app.dart';

/// El contador del HUD: con el archivo de Rive se dibuja en Rive; sin él,
/// cae al aspecto de Flutter. En los dos casos TalkBack lee lo mismo.
///
/// Usa las librerías nativas de rive_native (ver `rive_contract_test.dart`).
void main() {
  late rive.File file;

  setUpAll(() async {
    final bytes = await io.File(RiveUi.asset).readAsBytes();
    file = (await rive.File.decode(bytes, riveFactory: rive.Factory.flutter))!;
  });

  tearDownAll(() => file.dispose());

  Widget counter(int value) => Center(
    child: RiveCounter(
      value: value,
      semanticsLabel: 'Maíz: $value',
      fallback: Text('🌽 $value'),
    ),
  );

  testWidgets('sin el archivo de Rive muestra el respaldo', (tester) async {
    await tester.pumpWidget(testApp(counter(220)));

    expect(find.text('🌽 220'), findsOneWidget);
    expect(find.byType(rive.RiveWidget), findsNothing);
    expect(find.bySemanticsLabel('Maíz: 220'), findsOneWidget);
  });

  testWidgets('con el archivo se dibuja en Rive y sigue el número', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        counter(220),
        overrides: [riveFileProvider.overrideWithValue(file)],
      ),
    );

    expect(find.byType(rive.RiveWidget), findsOneWidget);
    expect(find.text('🌽 220'), findsNothing);
    expect(find.bySemanticsLabel('Maíz: 220'), findsOneWidget);

    // Sube (anima "gain") y baja (anima "loss") sin romperse.
    await tester.pumpWidget(
      testApp(
        counter(232),
        overrides: [riveFileProvider.overrideWithValue(file)],
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(
      testApp(
        counter(172),
        overrides: [riveFileProvider.overrideWithValue(file)],
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('Maíz: 172'), findsOneWidget);
  });

  // Si la fuente del .riv queda sin los glifos de los números (pasó en la
  // Fase 1 con un recorte de caracteres mal escrito), la pastilla se
  // dibuja vacía y ningún otro test lo nota: aquí se cuentan los píxeles
  // del color del texto en la mitad derecha, donde va el número.
  testWidgets('el número se dibuja de verdad', (tester) async {
    final boundary = GlobalKey();
    await tester.pumpWidget(
      testApp(
        Center(
          child: RepaintBoundary(key: boundary, child: counter(888)),
        ),
        overrides: [riveFileProvider.overrideWithValue(file)],
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    final textPixels = await tester.runAsync(() async {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 3);
      final bytes = (await image.toByteData())!;
      var count = 0;
      for (var y = 0; y < image.height; y++) {
        for (var x = image.width ~/ 2; x < image.width; x++) {
          final i = (y * image.width + x) * 4;
          // El texto es #4A1302 (marrón muy oscuro).
          final dark =
              bytes.getUint8(i) < 110 &&
              bytes.getUint8(i + 1) < 60 &&
              bytes.getUint8(i + 2) < 40 &&
              bytes.getUint8(i + 3) > 200;
          if (dark) count++;
        }
      }
      return count;
    });

    expect(textPixels, greaterThan(200));
  });

  testWidgets('crece con la letra grande y el "+N" no empuja', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      testApp(
        counter(9999),
        overrides: [riveFileProvider.overrideWithValue(file)],
      ),
    );

    // Lo que ocupa en el HUD es la pastilla; el dibujo de Rive es más alto
    // porque el "+N" flota debajo.
    final size = tester.getSize(find.byType(RiveCounter));
    expect(size.height, closeTo(RiveCounter.height * 1.3, 0.01));
    expect(
      tester.getSize(find.byType(rive.RiveWidget)).height,
      greaterThan(size.height),
    );
  });

  testWidgets('con otro ícono y en peligro, sin romperse', (tester) async {
    Widget potatoes(int value) => testApp(
      Center(
        child: RiveCounter(
          value: value,
          icon: RiveIcon.potato,
          danger: value <= 3,
          semanticsLabel: 'Papas: $value',
          fallback: Text('🥔 $value'),
        ),
      ),
      overrides: [riveFileProvider.overrideWithValue(file)],
    );

    await tester.pumpWidget(potatoes(5));
    await tester.pumpWidget(potatoes(3));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpWidget(potatoes(4));
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('Papas: 4'), findsOneWidget);
  });
}
