import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/app/rive/rive_ui.dart';
import 'package:guardianes_chacra/dev/ui_catalog_screen.dart';
import 'package:rive/rive.dart' as rive;

import '../helpers/test_app.dart';

/// El catálogo de desarrollo se abre y sus controles responden, con y sin
/// el archivo de Rive.
///
/// Usa las librerías nativas de rive_native (ver `rive_contract_test.dart`).
void main() {
  late rive.File file;

  setUpAll(() async {
    final bytes = await io.File(RiveUi.asset).readAsBytes();
    file = (await rive.File.decode(bytes, riveFactory: rive.Factory.flutter))!;
  });

  tearDownAll(() => file.dispose());

  for (final withRive in [false, true]) {
    testWidgets(withRive ? 'con Rive' : 'sin Rive', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        testApp(
          const UiCatalogScreen(),
          overrides: [if (withRive) riveFileProvider.overrideWithValue(file)],
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Con Rive, el artboard Catalog ocupa la primera pantalla.
      await tester.scrollUntilVisible(find.bySemanticsLabel('Mejorar'), 200);
      await tester.tap(find.bySemanticsLabel('Mejorar'));
      await tester.pump();
      expect(find.text('No alcanza el maíz'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.bySemanticsLabel('Ganar estrellas'),
        200,
      );
      await tester.tap(find.bySemanticsLabel('Ganar estrellas'));
      await tester.pump(const Duration(seconds: 2));

      expect(tester.takeException(), isNull);
    });
  }
}
