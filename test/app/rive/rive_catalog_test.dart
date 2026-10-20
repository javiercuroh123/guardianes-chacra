import 'dart:io' as io;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/app/rive/rive_ui.dart';
import 'package:rive/rive.dart' as rive;

/// Dibuja el artboard `Catalog` (todos los componentes del kit en todos sus
/// estados, con los datos guardados en el archivo) y busca el color de cada
/// estado: si un enlace de datos se rompe en el editor, falta su color.
///
/// Para ver la imagen:
/// `flutter test test/app/rive/rive_catalog_test.dart
/// --dart-define=CATALOG_PNG=build/catalog.png`.
///
/// Usa las librerías nativas de rive_native (ver `rive_contract_test.dart`).
void main() {
  testWidgets('el Catalog dibuja cada estado', (tester) async {
    late rive.File file;
    await tester.runAsync(() async {
      final bytes = await io.File(RiveUi.asset).readAsBytes();
      file = (await rive.File.decode(
        bytes,
        riveFactory: rive.Factory.flutter,
      ))!;
    });
    final controller = rive.RiveWidgetController(
      file,
      artboardSelector: rive.ArtboardSelector.byName('Catalog'),
      stateMachineSelector: rive.StateMachineSelector.byName(
        RiveUi.stateMachine,
      ),
    );
    final viewModel = controller.dataBind(rive.DataBind.auto());
    final boundary = GlobalKey();
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          key: boundary,
          child: SizedBox(
            width: 1000,
            height: 640,
            child: rive.RiveWidget(controller: controller),
          ),
        ),
      ),
    );
    // Lo suficiente para que terminen las entradas (estrella, panel…).
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    final counts = await tester.runAsync(() async {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage();
      const path = String.fromEnvironment('CATALOG_PNG');
      if (path.isNotEmpty) {
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        await io.File(path).writeAsBytes(png!.buffer.asUint8List());
      }
      final bytes = (await image.toByteData())!;
      final found = {for (final name in _colors.keys) name: 0};
      for (var i = 0; i < bytes.lengthInBytes; i += 4) {
        final r = bytes.getUint8(i);
        final g = bytes.getUint8(i + 1);
        final b = bytes.getUint8(i + 2);
        for (final MapEntry(:key, :value) in _colors.entries) {
          if ((r - value.$1).abs() < 12 &&
              (g - value.$2).abs() < 12 &&
              (b - value.$3).abs() < 12) {
            found[key] = found[key]! + 1;
          }
        }
      }
      return found;
    });

    for (final MapEntry(:key, :value) in counts!.entries) {
      expect(value, greaterThan(40), reason: 'no se ve: $key');
    }

    viewModel.dispose();
    controller.dispose();
    file.dispose();
  });
}

/// El color de cada estado (RGB de la paleta, ver `docs/UI_RIVE.md`).
const _colors = {
  'botón principal (maíz)': (0xFD, 0xB1, 0x19),
  'redondo en peligro (rojo)': (0xC4, 0x34, 0x03),
  'barra del jefe (terracota)': (0xB5, 0x45, 0x2A),
  'aviso del jefe (ciruela)': (0x8B, 0x20, 0x55),
  'interruptor encendido (verde)': (0x36, 0x90, 0x1D),
  'estrella llena': (0xFE, 0xCE, 0x18),
  'deshabilitado (gris)': (0xD8, 0xDB, 0xCF),
};
